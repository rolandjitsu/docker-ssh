FROM priv-repo AS builder

RUN rsync -rv --exclude '.git' $PRIV_SOURCE_CODE/ /tmp/

FROM scratch
COPY --from=builder /tmp/ /
