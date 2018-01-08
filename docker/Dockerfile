FROM docker.io/golang:1.9.2-alpine
RUN apk add --no-cache bash git openssh
RUN mkdir -p src/github.com/Ppamo/realize && \
	git clone -b "v2.0" https://github.com/Ppamo/realize.git src/github.com/Ppamo/realize && \
	cd src/github.com/Ppamo/realize && \
	go get -v
CMD ["realize", "start"]
