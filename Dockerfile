# Invocation:
#
# docker build -t acme-dns-with-subdomains:$(git describe) .
#
FROM golang:alpine AS builder
LABEL maintainer="joona@kuori.org"

RUN apk add --update gcc musl-dev git

ENV GOPATH /tmp/buildcache
RUN git clone https://github.com/joohoi/acme-dns /tmp/acme-dns
WORKDIR /tmp/acme-dns
RUN CGO_ENABLED=1 go build

FROM alpine:latest

WORKDIR /
COPY --from=builder /go/src/acme-dns/acme-dns-improved /
RUN mkdir -p /etc/acme-dns && mkdir -p /var/lib/acme-dns
RUN apk --no-cache add ca-certificates && update-ca-certificates

VOLUME ["/etc/acme-dns", "/var/lib/acme-dns"]
ENTRYPOINT ["/acme-dns-improved"]
EXPOSE 53 80 443
EXPOSE 53/udp
