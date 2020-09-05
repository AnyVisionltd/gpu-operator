### Reference command for Gravity clusters (ChartMuseum push invocation):
```
gravity app install --name=gpu-operator --set global.localRegistry="leader.telekube.local:5000/" --set global.services.enabled=false --set global.invocation.enabled=true --set extraEnvironmentVars.auto_install_product=true [TAR_PACKAGE]
```

### Reference command for generic Kubernetes clusters (No invocation, plain helm install):
```
gravity app install --name=gpu-operator --set global.localRegistry="localhost:5000/" --registry=localhost:5000 --insecure [TAR_PACKAGE]
```

### Note:
Might require manual `kubectl label nodes [NODES] feature.node.kubernetes.io/pci-10de.present=true` if NFD does not label the GPU nodes automatically.
