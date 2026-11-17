# syntax=docker/dockerfile:1
FROM priv-repo AS builder

RUN rsync -av --exclude '.git' $PRIV_SOURCE_CODE/ /tmp/out/

FROM scratch
COPY --from=builder /tmp/out/ /
