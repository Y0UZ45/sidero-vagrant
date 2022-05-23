#!/bin/bash
source /vagrant/lib.sh


clusterapi_version="${1:-1.0.4}"; shift || true

mkdir /root/.cluster-api

cat <<EOF >/root/.cluster-api/clusterctl.yaml
providers:
  - name: "talos"
    url: "https://github.com/siderolabs/cluster-api-bootstrap-provider-talos/releases/latest/bootstrap-components.yaml"
    type: "BootstrapProvider"
  - name: "talos"
    url: "https://github.com/siderolabs/cluster-api-control-plane-provider-talos/releases/latest/control-plane-components.yaml"
    type: "ControlPlaneProvider"
  - name: "sidero"
    url: "https://github.com/siderolabs/sidero/releases/latest/infrastructure-components.yaml"
    type: "InfrastructureProvider"
EOF

title "Installing clusterctl $clusterapi_version"
wget -qO /usr/local/bin/clusterctl "https://github.com/kubernetes-sigs/cluster-api/releases/download/v$clusterapi_version/clusterctl-linux-amd64"
chmod +x /usr/local/bin/clusterctl
clusterctl version
cp /usr/local/bin/clusterctl /vagrant/shared
