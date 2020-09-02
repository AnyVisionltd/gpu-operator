#!/bin/bash
set -ex

printf '####### Packing chart...\n'
tar czf ${CHART_NAME}.tgz ${CHART_NAME}
printf '####### Deleting old chart from ChartMuseum...\n'
curl -sS -X DELETE http://chartmuseum.infra.svc:8080/api/charts/${CHART_NAME}/${CHART_VERSION} || true
printf '####### Pushing chart to ChartMuseum...\n'
curl -sS --data-binary "@${CHART_NAME}.tgz" http://chartmuseum.infra.svc:8080/api/charts
printf '\n\n'

RANCHER_SERVER_BASE=https://rancher.cattle-system.svc.cluster.local
APITOKEN=$(jq -r .Servers.rancherDefault.tokenKey < /etc/rancher/cli2.json)
printf '####### Login to Rancher...\n'
for i in {1..5}; do rancher login ${RANCHER_SERVER_BASE} --token ${APITOKEN} --skip-verify > /dev/null 2>&1 && break || sleep 3; done;
printf '####### Refreshing Rancher Catalog...\n'
rancher catalog refresh catalog --wait

if [[ "${auto_install_product:-false}" == "true" ]]; then
    printf "####### Installing ${CHART_NAME}\n"
    rancher app install --no-prompt --set=global.localRegistry=leader.telekube.local:5000/ --version ${CHART_VERSION} --namespace ${namespace:-default} ${CHART_NAME} ${CHART_NAME}
    rancher wait --timeout 1200 ${CHART_NAME}
fi
