FROM mcr.microsoft.com/azure-cli:2.77.0

RUN tdnf install -y \
    git \
    jq \
    tar \
    gzip \
    curl \
    && tdnf clean all

COPY backup.sh /backup.sh

RUN chmod +x /backup.sh

ENTRYPOINT ["/backup.sh"]