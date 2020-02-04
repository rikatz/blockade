.DEFAULT_GOAL:=help

.EXPORT_ALL_VARIABLES:

ifndef VERBOSE
.SILENT:
endif

# set default shell
SHELL=/bin/bash -o pipefail

# 0.0.0 shouldn't clobber any released builds
TAG ?= 0.0.0

IMAGE = aledbf/blockade

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

PKG=github.com/aledbf/blockade

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: base-image
base-image: ## build docker base image containing mod-security
	@DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build \
		--load \
		--progress plain \
		--tag $(IMAGE):base-$(TAG) images/base

.PHONY: go-image
go-image: ## build go image to run tests
	@DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build \
		--load \
		--progress plain \
		--build-arg BASE_IMAGE="$(IMAGE):base-$(TAG)" \
		--build-arg GOLANG_VERSION=1.13.7 \
		--build-arg GOLANG_SHA=e4ad42cc5f5c19521fbbbde3680995f2546110b5c6aa2b48c3754ff7af9b41f4 \
		--tag $(IMAGE):go-$(TAG) images/go

.PHONY: test
test: ## run tests
	@docker run                                 \
		--rm                                   	\
		-e GOCACHE="/go/src/$(PKG)/.cache"     	\
		-e GO111MODULE=off                     	\
		-v "$(HOME)/.kube:$(HOME)/.kube"       	\
		-v "$(ROOT_DIR):/go/src/$(PKG)"       	\
		-w "/go/src/$(PKG)"                    	\
		-u $(shell id -u):$(shell id -g)   		\
		$(IMAGE):go-$(TAG) go test -v ./...
