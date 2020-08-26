# Project name
PROJECT=github.com/storageos/cluster-operator
# Current Operator version
VERSION ?= 2.2.0
# Default bundle image tag
BUNDLE_IMG ?= controller-bundle:$(VERSION)
# Options for 'bundle-build'
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

# Image URL to use all building/pushing image targets
IMG ?= controller:latest
# Produce CRDs that work back to Kubernetes 1.11 (no version conversion)
CRD_OPTIONS ?= "crd:trivialVersions=true"

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

# Version of go used for containerized builds.
GO_VERSION=1.15.0
# Go build cache directory for containerized builds.
CACHE_DIR=$(shell pwd)/.cache

# Operator-SDK binary name and version.
OSDK=operator-sdk
OSDK_VERSION=v1.0.0
MACHINE=$(shell uname -m)

# Golangci-lint version to use for code linting.
GOLANGCI_LINT=golangci-lint
GOLANGCI_LINT_VERSION="v1.30.0"

##@ General

# The help will print out all targets with their descriptions organized bellow their categories. The categories are represented by `##@` and the target descriptions by `##`.
# The awk commands is responsable to read the entire set of makefiles included in this invocation, looking for lines of the file as xyz: ## something, and then pretty-format the target and help. Then, if there's a line with ##@ something, that gets pretty-printed as a category.
# More info over the usage of ANSI control characters for terminal formatting: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info over awk command: http://linuxcommand.org/lc3_adv_awk.php
.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""
	@echo "To run any of the above in docker, suffix the command with '-docker':"
	@echo ""
	@echo "  make manager-docker"
	@echo ""

##@ Build

manager: generate golangci-lint ## Build the controller-manager binary
	go build -o bin/manager main.go

docker-build: test ## Build the docker image
	docker build . -t ${IMG}

docker-push: ## Push the docker image
	docker push ${IMG}

.PHONY: bundle
bundle: manifests ## Generate bundle manifests and metadata, then validate generated files
	operator-sdk generate kustomize manifests -q
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(IMG)
	$(KUSTOMIZE) build config/manifests | operator-sdk generate bundle -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS)
	operator-sdk bundle validate ./bundle


.PHONY: bundle-build
bundle-build: ## Build the bundle image.
	docker build -f bundle.Dockerfile -t $(BUNDLE_IMG) .

##@ Development

run: generate golangci-lint manifests ## Run against the configured Kubernetes cluster in ~/.kube/config
	go run ./main.go

lint: golangci-lint ## Run golangci-lint
	$(GOLANGCI_LINT) run

generate: controller-gen ## Generate code
	$(CONTROLLER_GEN) object:headerFile="hack/boilerplate.go.txt" paths="./..."

manifests: controller-gen ## Generate manifests e.g. CRD, RBAC etc.
	$(CONTROLLER_GEN) $(CRD_OPTIONS) rbac:roleName=manager-role webhook paths="./..." output:crd:artifacts:config=config/crd/bases

install: manifests kustomize ## Install CRDs into a cluster
	$(KUSTOMIZE) build config/crd | kubectl apply -f -

deploy: manifests kustomize ## Deploy controller in the configured Kubernetes cluster in ~/.kube/config
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/default | kubectl apply -f -

uninstall: manifests kustomize ## Uninstall CRDs from a cluster
	$(KUSTOMIZE) build config/crd | kubectl delete -f -

tidy: ## Prune, add and vendor go dependencies.
	go mod tidy -v
	go mod vendor -v

##@ Test

test: generate golangci-lint manifests ## Run tests
	go test ./... -coverprofile cover.out

# Binary tools

# find or download controller-gen
# download controller-gen if necessary
controller-gen:
ifeq (, $(shell which controller-gen))
	@{ \
	set -e ;\
	CONTROLLER_GEN_TMP_DIR=$$(mktemp -d) ;\
	cd $$CONTROLLER_GEN_TMP_DIR ;\
	go mod init tmp ;\
	go get sigs.k8s.io/controller-tools/cmd/controller-gen@v0.3.0 ;\
	rm -rf $$CONTROLLER_GEN_TMP_DIR ;\
	}
CONTROLLER_GEN=$(GOBIN)/controller-gen
else
CONTROLLER_GEN=$(shell which controller-gen)
endif

kustomize:
ifeq (, $(shell which kustomize))
	@{ \
	set -e ;\
	KUSTOMIZE_GEN_TMP_DIR=$$(mktemp -d) ;\
	cd $$KUSTOMIZE_GEN_TMP_DIR ;\
	go mod init tmp ;\
	go get sigs.k8s.io/kustomize/kustomize/v3@v3.5.4 ;\
	rm -rf $$KUSTOMIZE_GEN_TMP_DIR ;\
	}
KUSTOMIZE=$(GOBIN)/kustomize
else
KUSTOMIZE=$(shell which kustomize)
endif

operator-sdk:
ifeq (, $(shell which operator-sdk))
	{ \
	set -e ;\
	OSDK_TMP_DIR=$$(mktemp -d) ;\
	cd $$OSDK_TMP_DIR ;\
	curl -Lo $(OSDK) https://github.com/operator-framework/operator-sdk/releases/download/${OSDK_VERSION}/operator-sdk-${OSDK_VERSION}-${MACHINE}-linux-gnu ;\
	chmod +x $(OSDK) ;\
	rm -rf $$OSDK_TMP_DIR ;\
	}
OSDK=$(GOBIN)/operator-sdk
else
OSDK=$(shell which operator-sdk)
endif

golangci-lint:
ifeq (, $(shell which golangci-lint))
	@{ \
	set -e ;\
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(GOBIN) $(GOLANGCI_LINT_VERSION); \
	}
GOLANGCI_LINT=$(GOBIN)/golangci-lint
else
GOLANGCI_LINT=$(shell which golangci-lint)
endif

# This target matches any target ending in '-docker' eg. 'test-docker'. This
# allows running makefile targets inside a container by appending '-docker' to
# it.
%-docker:
	mkdir -p $(CACHE_DIR)/go $(CACHE_DIR)/cache
	# golangci-lint build cache.
	mkdir -p $(CACHE_DIR)/golangci-lint
	# Run the make target in docker.
	docker run -it --rm \
		-v $(CACHE_DIR)/go:/go \
		-v $(CACHE_DIR)/cache:/.cache/go-build \
		-v $(CACHE_DIR)/golangci-lint:/.cache/golangci-lint \
		-v $(shell pwd):/go/src/${PROJECT} \
		-w /go/src/${PROJECT} \
		-u $(shell id -u):$(shell id -g) \
		--entrypoint "make" \
		golang:$(GO_VERSION) \
		"$(patsubst %-docker,%,$@)"
