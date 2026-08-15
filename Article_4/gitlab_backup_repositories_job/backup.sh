#!/usr/bin/env bash

set -Eeuo pipefail

###############################################################################
# CONFIG
###############################################################################

DATE=$(date +"%Y-%m-%d")
YEAR=$(date +"%Y")
MONTH=$(date +"%m")

WORKDIR="/tmp/gitlab-backup"
REPOS_DIR="${WORKDIR}/repos"

ARCHIVE_NAME="gitlab-${DATE}.tar.gz"
ARCHIVE_PATH="${WORKDIR}/${ARCHIVE_NAME}"

###############################################################################
# VALIDATION
###############################################################################

required_vars=(
  GITLAB_USERNAME
  GITLAB_TOKEN
  GITLAB_URL

  AZURE_STORAGE_ACCOUNT

  AZURE_CLIENT_ID
  AZURE_CLIENT_SECRET
  AZURE_TENANT_ID
)

for var in "${required_vars[@]}"
do
  if [[ -z "${!var:-}" ]]; then
    echo "[ERROR] Missing variable: ${var}"
    exit 1
  fi
done

###############################################################################
# AZURE LOGIN
###############################################################################

echo "[INFO] Logging into Azure"

az login \
  --service-principal \
  --username "${AZURE_CLIENT_ID}" \
  --password "${AZURE_CLIENT_SECRET}" \
  --tenant "${AZURE_TENANT_ID}" \
  --output none

###############################################################################
# WORKSPACE
###############################################################################

echo "[INFO] Preparing workspace"

rm -rf "${WORKDIR}"

mkdir -p "${REPOS_DIR}"

###############################################################################
# FETCH GROUPS
###############################################################################

echo "[INFO] Fetching groups"

PAGE=1

while true
do

  RESPONSE=$(
    curl \
      --silent \
      --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
      "${GITLAB_URL}/api/v4/groups?per_page=100&page=${PAGE}"
  )

  COUNT=$(echo "${RESPONSE}" | jq length)

  if [[ "${COUNT}" -eq 0 ]]; then
    break
  fi

  echo "${RESPONSE}" \
    | jq -c '.[]' \
    >> "${WORKDIR}/groups.jsonl"

  PAGE=$((PAGE + 1))

done

###############################################################################
# FETCH PROJECTS BY GROUP
###############################################################################

echo "[INFO] Fetching projects by group"

while read -r GROUP
do

  GROUP_ID=$(echo "${GROUP}" | jq -r '.id')
  GROUP_NAME=$(echo "${GROUP}" | jq -r '.full_path')

  echo "[INFO] Processing group: ${GROUP_NAME}"

  mkdir -p "${REPOS_DIR}/${GROUP_NAME}"

  PAGE=1

  while true
  do

    RESPONSE=$(
      curl \
        --silent \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/groups/${GROUP_ID}/projects?include_subgroups=true&per_page=100&page=${PAGE}"
    )

    COUNT=$(echo "${RESPONSE}" | jq length)

    if [[ "${COUNT}" -eq 0 ]]; then
      break
    fi

    echo "${RESPONSE}" \
      | jq -r --arg group "${GROUP_NAME}" \
      '.[] | "\($group)|\(.http_url_to_repo)"' \
      >> "${WORKDIR}/repos.txt"

    PAGE=$((PAGE + 1))

  done

done < "${WORKDIR}/groups.jsonl"

###############################################################################
# REMOVE DUPLICATES
###############################################################################

echo "[INFO] Removing duplicate repositories"

sort -u "${WORKDIR}/repos.txt" -o "${WORKDIR}/repos.txt"

###############################################################################
# CLONE REPOSITORIES
###############################################################################

echo "[INFO] Cloning repositories"

while IFS='|' read -r GROUP_NAME REPO
do

  [[ -z "${REPO}" ]] && continue

  NAME=$(basename "${REPO}" .git)

  echo "[INFO] Backing up ${GROUP_NAME}/${NAME}"

  mkdir -p "${REPOS_DIR}/${GROUP_NAME}"

  git clone \
    --mirror \
    "https://${GITLAB_USERNAME}:${GITLAB_TOKEN}@${REPO#https://}" \
    "${REPOS_DIR}/${GROUP_NAME}/${NAME}.git"

done < "${WORKDIR}/repos.txt"

###############################################################################
# ARCHIVE
###############################################################################

echo "[INFO] Creating archive"

tar \
  -czf "${ARCHIVE_PATH}" \
  -C "${REPOS_DIR}" \
  .

ls -lh "${ARCHIVE_PATH}"

###############################################################################
# UPLOAD
###############################################################################

echo "[INFO] Uploading archive"

az storage blob upload \
  --auth-mode login \
  --account-name "${AZURE_STORAGE_ACCOUNT}" \
  --container-name "gitlab" \
  --name "${YEAR}/${MONTH}/${ARCHIVE_NAME}" \
  --file "${ARCHIVE_PATH}" \
  --overwrite true \
  --output none

###############################################################################
# CLEANUP
###############################################################################

echo "[INFO] Cleaning workspace"

rm -rf "${WORKDIR}"

echo "[SUCCESS] Backup completed"