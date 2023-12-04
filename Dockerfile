# Invocation:
#
# docker build -t acme-dns-with-subdomains:$(git describe) .
#
FROM golang:alpine AS builder
LABEL maintainer="joona@kuori.org"

RUN apk add --update gcc musl-dev git

#RUN git clone https://github.com/joohoi/acme-dns /tmp/acme-dns
COPY . /go/src/acme-dns
RUN chown -R guest: /go
RUN sed -i -e 's@^\(guest:x:[0-9]*:[0-9]*\)@\1:Dev:/go/src/acme-dns:/bin/sh@' \
    /etc/passwd
USER guest
WORKDIR /go/src/acme-dns

RUN go get .
RUN go get -t .
RUN CGO_ENABLED=0 go build -v
RUN go test
RUN fail=0; for x in *.go; do \
    cp $x $x.orig; go fmt $x && diff $x.orig $x || fail=1; done; \
    test $fail -eq 0

FROM alpine:latest
LABEL description="acmedns, but with subdomains; manual build/push to harbor"
LABEL dockerfile-vcs="https://github.com/ossobv/acme-dns-with-subdomains"

WORKDIR /
COPY --from=builder /go/src/acme-dns/acme-dns-with-subdomains /
RUN mkdir -p /etc/acme-dns && mkdir -p /var/lib/acme-dns
RUN apk --no-cache add ca-certificates && update-ca-certificates

VOLUME ["/etc/acme-dns", "/var/lib/acme-dns"]
ENTRYPOINT ["/acme-dns-with-subdomains"]
EXPOSE 53 80 443
EXPOSE 53/udp
