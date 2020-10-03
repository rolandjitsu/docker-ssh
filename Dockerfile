FROM priv-repo AS builder

RUN cp -av $PRIV_SOURCE_CODE/. /tmp/

FROM scratch
COPY --from=builder /tmp/ /
