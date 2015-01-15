NAME=sv-rollout
VERSION=$(shell cat VERSION)
DEB=pkg/$(NAME)_$(VERSION)_amd64.deb

GOFILES=$(shell find . -type f -name '*.go')
MANFILES=$(shell find man -name '*.ronn' -exec echo build/{} \; | sed 's/\.ronn/\.gz/')

GODEP_PATH=$(shell pwd)/Godeps/_workspace

BUNDLE_EXEC=bundle exec

.PHONY: default all binaries man clean dev_bootstrap deb

default: all
all: deb
binaries: build/bin/linux-amd64
deb: $(DEB)
man: $(MANFILES)

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir  := $(abspath $(dir $(mkfile_path)))

build/man/%.gz: man/%.ronn
	mkdir -p "$(@D)"
	$(BUNDLE_EXEC) ronn -r --pipe "$<" | gzip > "$@"

build/bin/linux-amd64: $(GOFILES) version.go
	if [ $(shell uname -s) != 'Linux' ] ; then \
		GOPATH=$(GODEP_PATH):$$GOPATH gox -osarch="linux/amd64" -output="$@" . ; else \
		GOPATH=$(GODEP_PATH):$$GOPATH go build -o $@ . ; fi

version.go: VERSION
	echo 'package main\n\nconst VERSION string = "$(VERSION)"' > $@

$(DEB): build/bin/linux-amd64 man
	mkdir -p $(@D)
	$(BUNDLE_EXEC) fpm \
		-t deb \
		-s dir \
		--name="$(NAME)" \
		--version="$(VERSION)" \
		--package="$@" \
		--license=MIT \
		--category=admin \
		--no-depends \
		--no-auto-depends \
		--architecture=amd64 \
		--maintainer="Burke Libbey <burke.libbey@shopify.com>" \
		--description="utility to restart multiple runit services concurrently" \
		--url="https://github.com/Shopify/sv-rollout" \
		./build/man/=/usr/share/man/ \
		./$<=/usr/bin/$(NAME)

clean:
	rm -rf build pkg

dev_bootstrap: version.go
	if [ $(shell uname -s) != 'Linux' ] ; then go get github.com/mitchellh/gox; gox -build-toolchain -osarch="linux/amd64"; fi
	bundle install
