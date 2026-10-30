# arm64 image of Mattermost Team Edition, built from the official signed release tarball.
# Mirrors upstream server/build/Dockerfile, minus the optional document-text extractors
# (their library paths in upstream are amd64-specific).
FROM ubuntu:noble-20260917@sha256:534baea6a22c03a63003dbc8dbe78fe34bc0d7e595d9a9dc9834884ff530eb55 AS builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG MM_VERSION
ARG MM_ARCH=arm64
# Fingerprint of "Mattermost Build <dev-ops@mattermost.com>" (signs every release tarball)
ARG MM_KEY_FPR=A1B31D46F0F3A10B02CF2D44F8F2C31744774B28
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y ca-certificates curl gnupg media-types mailcap tzdata \
  && rm -rf /var/lib/apt/lists/*
COPY mattermost-release.gpg /tmp/mattermost-release.gpg
RUN set -eux; test -n "${MM_VERSION}"; cd /tmp; \
  export GNUPGHOME=/tmp/gnupg; mkdir -m 700 $GNUPGHOME; \
  gpg --batch --import mattermost-release.gpg; \
  gpg --batch --list-keys --with-colons | grep -q "^fpr:::::::::${MM_KEY_FPR}:"; \
  pkg="mattermost-team-${MM_VERSION}-linux-${MM_ARCH}.tar.gz"; \
  curl -fsSLO "https://releases.mattermost.com/${MM_VERSION}/${pkg}"; \
  curl -fsSLO "https://releases.mattermost.com/${MM_VERSION}/${pkg}.sig"; \
  gpg --batch --status-fd 1 --verify "${pkg}.sig" "${pkg}" | grep -q "VALIDSIG ${MM_KEY_FPR}"; \
  mkdir -p /out && tar -C /out -xzf "${pkg}"; \
  mkdir -p /out/mattermost/data /out/mattermost/plugins /out/mattermost/client/plugins /out/mattermost/logs /out/mattermost/config /out/mattermost/.postgresql; \
  chmod 700 /out/mattermost/.postgresql; \
  chown -R 2000:2000 /out/mattermost; \
  rm -rf /tmp/*

FROM gcr.io/distroless/base-debian12@sha256:fabbf1c0c357a3d42550111351daed089b20a2c954df13ee2fcff60602515e84
ARG MM_VERSION
LABEL org.opencontainers.image.source="https://github.com/kiukairor-org/mattermost-arm64" \
      org.opencontainers.image.description="Mattermost Team Edition ${MM_VERSION} (arm64), from the official signed tarball" \
      org.opencontainers.image.version="${MM_VERSION}"
ENV PATH="/mattermost/bin:${PATH}" \
    MM_SERVICESETTINGS_ENABLELOCALMODE="true" \
    MM_INSTALL_TYPE="docker"
COPY --from=builder /etc/mime.types /etc/mime.types
COPY --from=builder --chown=2000:2000 /etc/ssl/certs /etc/ssl/certs
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder --chown=2000:2000 /out/mattermost /mattermost
COPY passwd /etc/passwd
USER mattermost
WORKDIR /mattermost
CMD ["/mattermost/bin/mattermost"]
EXPOSE 8065 8067 8074
VOLUME ["/mattermost/data", "/mattermost/logs", "/mattermost/config", "/mattermost/plugins", "/mattermost/client/plugins"]
