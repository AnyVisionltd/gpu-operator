#!/bin/bash
set -ex

CHARTMUSEUM_SERVER_URL=${CHARTMUSEUM_SERVER_URL:-"http://chartmuseum.infra.svc:8080"}
RANCHER_SERVER_URL=${RANCHER_SERVER_URL:-"https://rancher.cattle-system.svc.cluster.local"}
REGISTRY_URL=${localRegistry:-"leader.telekube.local:5000/"}
APITOKEN=$(jq -r .Servers.rancherDefault.tokenKey < /etc/rancher/cli2.json)
NAMESPACE=${namespace:-"default"}
AUTO_INSTALL_PRODUCT=${auto_install_product:-"false"}

printf '####### Packing chart...\n'
tar czf ${CHART_NAME}.tgz ${CHART_NAME}
printf '####### Deleting old chart from ChartMuseum...\n'
curl -sS -X DELETE ${CHARTMUSEUM_SERVER_URL}/api/charts/${CHART_NAME}/${CHART_VERSION} || true
printf '####### Pushing chart to ChartMuseum...\n'
curl -sS --data-binary "@${CHART_NAME}.tgz" ${CHARTMUSEUM_SERVER_URL}/api/charts
printf '\n\n'

printf '####### Login to Rancher...\n'
for i in {1..5}; do rancher login ${RANCHER_SERVER_URL} --token ${APITOKEN} --skip-verify > /dev/null 2>&1 && break || sleep 3; done;
printf '####### Refreshing Rancher Catalog...\n'
rancher catalog refresh catalog --wait

if [[ ${AUTO_INSTALL_PRODUCT} == "true" ]]; then
    printf "####### Installing ${CHART_NAME}\n"
    rancher app install --no-prompt --set=global.localRegistry=${REGISTRY_URL} ${RANCHER_APP_INSTALL_EXTRA_FLAGS} --version ${CHART_VERSION} --namespace ${NAMESPACE} ${CHART_NAME} ${CHART_NAME}
    rancher wait --timeout 1200 ${CHART_NAME}
fi
