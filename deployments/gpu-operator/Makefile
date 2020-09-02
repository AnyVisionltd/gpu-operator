CHART_NAME := $(shell cat ./Chart.yaml | grep ^name: | cut -d":" -f 2 |  tr -d "[:space:]" | tr -d '"')
CHART_VERSION := $(shell cat ./Chart.yaml | grep ^version: | cut -d":" -f 2 |  tr -d "[:space:]" | tr -d '"')
HELM ?= microk8s helm
TELE ?= tele
YQ ?= yq
DOCKER ?= docker
CATALOG_USERNAME ?= ""
CATALOG_PASSWORD ?= ""
RAND := $(shell cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
export

EXTRA_GRAVITY_OPTIONS ?=


.PHONY: values pull invocation app-package cleanup all build


values:
		## Install YQ
		#curl -sL https://github.com/mikefarah/yq/releases/download/3.3.2/yq_linux_amd64 -o /usr/bin/yq && chmod +x /usr/bin/yq
		## Update values.yaml
		$(YQ) w values.yaml.tmpl 'invocationImage.imageName' "invocation-images/${CHART_NAME}" > values.yaml
		$(YQ) w -i values.yaml 'invocationImage.imageTag' "${CHART_VERSION}-${RAND}"


pull:
		$(HELM) init --client-only
		$(HELM) dep update
		$(HELM) template --values values.yaml --set global.extraImages=true . | grep "image: " | grep '^[[:blank:]]*[^[:blank:]#]' | grep -v "invocation" | sed -E 's/.+image: (.+)/\1/' | sed -E 's/"//g' | uniq | xargs -I {} -n1 docker pull {}


invocation:
		## Build the invocation image
		$(DOCKER) build -t invocation-images/${CHART_NAME}:${CHART_VERSION}-${RAND} -f Dockerfile --build-arg CHART_NAME=${CHART_NAME} --build-arg CHART_VERSION=${CHART_VERSION} .


app-package:
		rm -f *.tar
		$(TELE) build --verbose --overwrite --values values.yaml --set global.extraImages=true --set global.invocation.enabled=true --output $(CHART_NAME)-$(CHART_VERSION)-app-image.tar .


cleanup:
		rm -rf /tmp/gravity* /tmp/runtime* ~/.gravity/cache


all: values pull invocation app-package cleanup


build: values invocation app-package cleanup
