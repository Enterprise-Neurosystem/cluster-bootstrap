# Cluster Bootstrap

[![Spelling](https://github.com/Enterprise-Neurosystem/cluster-bootstrap/actions/workflows/spellcheck.yaml/badge.svg)](https://github.com/Enterprise-Neurosystem/cluster-bootstrap/actions/workflows/spellcheck.yaml)
[![Linting](https://github.com/Enterprise-Neurosystem/cluster-bootstrap/actions/workflows/validate-manifests.yaml/badge.svg)](https://github.com/Enterprise-Neurosystem/cluster-bootstrap/actions/workflows/validate-manifests.yaml)

This project is designed to bootstrap an OpenShift cluster using ArgoCD.

This repo is subject to frequent breaking changes while we all learn patterns to use as a team.

## Prerequisites

OpenShift 4.10+ with `cluster-admin`.

This has been tested with the [Red Hat Demo Platform](https://demo.redhat.com) using the following selection:

- `Red Hat OpenShift Container Platform 4 Demo`
- `OpenShift Version`: 4.10 (or greater)

### Client

In order to bootstrap this repository you must have the following cli tools:

- `oc` - Download [mac](https://formulae.brew.sh/formula/openshift-cli), [linux](https://mirror.openshift.com/pub/openshift-v4/clients)
- `kustomize` (optional) - Download [mac](https://formulae.brew.sh/formula/kustomize), [linux](https://github.com/kubernetes-sigs/kustomize/releases)

## Bootstrapping a Cluster

1. Verify you are logged into your cluster using `oc`.
1. Clone this repository to your local environment.

```
oc whoami
git clone <repo>
```

### Quick Start

Execute the following script:

```sh
scripts/bootstrap.sh
```

```
# setup workshop (optional)
. scripts/workshop_functions.sh
```

The `bootstrap.sh` script will:

- Install the OpenShift GitOps Operator
- Create an ArgoCD instance in the `openshift-gitops` namespace
- Bootstrap a set of ArgoCD applications to configure the cluster

## Additional Configurations

### Sandbox Namespace

The `sandbox` [namespace](components/configs/namespaces/instance/sandbox/sandbox-namespace.yaml) is useable by all [authenticated users](components/configs/namespaces/instance/sandbox/sandbox-edit.yaml). All objects in the sandbox are [cleaned out weekly](components/configs/simple/sandbox-cleanup/sandbox-cleanup-cj.yml).

## Additional Info

- [Fix GitHub Login - Update Oauth Callback](docs/LOGIN.md)

## External Links

- [ArgoCD - Example](https://github.com/gnunn-gitops/cluster-config)
- [ArgoCD - Patterns](https://github.com/gnunn-gitops/standards)
