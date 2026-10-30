# mattermost-arm64

Official Mattermost Team Edition Docker images are amd64-only. This repo builds
`ghcr.io/kiukairor-org/mattermost-team-edition:<version>` for **linux/arm64** from the
official release tarball, verifying its GPG signature against the Mattermost Build key
(`A1B31D46F0F3A10B02CF2D44F8F2C31744774B28`, from `https://deb.packages.mattermost.com/pubkey.gpg`).

Bump: edit `MM_VERSION`, push to `main`.
