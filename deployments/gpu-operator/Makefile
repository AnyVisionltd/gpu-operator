# workspace vars
ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PARENT_ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)

# helm vars
HELM ?= helm
CATALOG_NAME ?= services
CHART_NAME ?= $(shell cat ./Chart.yaml | grep ^name: | cut -d":" -f 2 |  tr -d "[:space:]" | tr -d '"')
CHART_VERSION ?= $(shell cat ./Chart.yaml | grep ^version: | cut -d":" -f 2 |  tr -d "[:space:]" | tr -d '"')
HELM_SVC_CATALOG_URL ?= https://chart.tls.ai/services
HELM_SVC_CATALOG_CRED_USR ?=
HELM_SVC_CATALOG_CRED_PSW ?=

# gravity vars
TELE ?= tele
TELE_STATE_DIR ?= /var/lib/tele-cache

# invocation vars
YQ ?= yq
DOCKER ?= docker
RAND := $(shell cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)


.PHONY: helm-prepare
helm-prepare:
	$(HELM) init --client-only
	@$(HELM) repo add --username $(HELM_SVC_CATALOG_CRED_USR) --password $(HELM_SVC_CATALOG_CRED_PSW) $(CATALOG_NAME) $(HELM_SVC_CATALOG_URL)


.PHONY: helm-dep-update
helm-dep-update:
	$(HELM) dependency update $(ROOT_DIR)


.PHONY: helm-package
helm-package:
	cp -f $(ROOT_DIR)/values.yaml.tmpl $(ROOT_DIR)/values.yaml
	$(HELM) package --version $(CHART_VERSION) $(ROOT_DIR)


.PHONY: helm-push
helm-push:
	$(HELM) push $(ROOT_DIR)/$(CHART_NAME)-$(CHART_VERSION).tgz $(CATALOG_NAME) --force


.PHONY: values
values:
	## Update values.yaml
	$(YQ) w $(ROOT_DIR)/values.yaml.tmpl 'invocationImage.imageName' "invocation-images/$(CHART_NAME)" > $(ROOT_DIR)/values.yaml
	$(YQ) w -i $(ROOT_DIR)/values.yaml 'invocationImage.imageTag' "$(CHART_VERSION)-$(RAND)"


.PHONY: docker-pull
docker-pull:
	$(HELM) template --values $(ROOT_DIR)/values.yaml --set global.extraImages=true $(ROOT_DIR) | grep "image: " | grep '^[[:blank:]]*[^[:blank:]#]' | grep -v "invocation" | sed -E 's/.+image: (.+)/\1/' | sed -E 's/"//g' | uniq | grep -Ev '^(nvidia-driver|container-toolkit|k8s-device-plugin|dcgm-exporter|cuda-sample|gpu-feature-discovery)' | xargs -I {} -n1 docker pull {}


.PHONY: invocation
invocation:
	## Install YQ
	#curl -sL https://github.com/mikefarah/yq/releases/download/3.3.2/yq_linux_amd64 -o /usr/bin/yq && chmod +x /usr/bin/yq

	## Build the invocation image
	$(DOCKER) build -t invocation-images/$(CHART_NAME):$(CHART_VERSION)-$(RAND) -f $(ROOT_DIR)/Dockerfile --build-arg CHART_NAME=$(CHART_NAME) --build-arg CHART_VERSION=$(CHART_VERSION) $(ROOT_DIR)


.PHONY: gravity-app-package
gravity-app-package:
	rm -f $(CHART_NAME)-$(CHART_VERSION)-app-image.tar
	$(TELE) build --state-dir=$(TELE_STATE_DIR) --verbose --overwrite --values $(ROOT_DIR)/values.yaml --set global.extraImages=true --set global.invocation.enabled=true \
		--output $(CHART_NAME)-$(CHART_VERSION)-app-image.tar $(ROOT_DIR)


.PHONY: cleanup
cleanup:
	rm -rf /tmp/gravity* /tmp/runtime* ~/.gravity/cache


.PHONY: helm
helm: helm-prepare helm-package helm-push


.PHONY: gravity
gravity: values invocation gravity-app-package


.PHONY: build
build: helm-dep-update values docker-pull invocation gravity-app-package


.PHONY: all
all: helm values docker-pull invocation gravity-app-package cleanup
