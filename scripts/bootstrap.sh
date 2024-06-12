#!/bin/bash
set -e
# set -x

# shellcheck source=/dev/null
source "$(dirname "$0")/functions.sh"

LANG=C
SLEEP_SECONDS=8
RHDP_NAME=ocp4-workshop-aiml-edge
ARGO_NS="openshift-gitops"
ARGO_CHANNEL="gitops-1.9"
ARGO_DEPLOY_STABLE=(cluster kam openshift-gitops-applicationset-controller openshift-gitops-redis openshift-gitops-repo-server openshift-gitops-server)

# kludge: rhdp setup
if [ "${1}" == "${RHDP_NAME}" ]; then
  export NON_INTERACTIVE=true
  export EDGE_WORKSHOP=true
  bootstrap_dir=bootstrap/overlays/workshop-rhdp
fi

wait_for_gitops(){
  echo "Waiting for operator to start"
  until oc get deployment gitops-operator-controller-manager -n openshift-gitops-operator >/dev/null 2>&1
  do
    sleep 1
  done

  echo "Waiting for openshift-gitops namespace to be created"
  until oc get ns ${ARGO_NS} >/dev/null 2>&1
  do
    sleep 1
  done

  echo "Waiting for deployments to start"
  until oc get deployment cluster -n ${ARGO_NS} >/dev/null 2>&1
  do
    sleep 1
  done

  echo "Waiting for all pods to be created"
  for i in "${ARGO_DEPLOY_STABLE[@]}"
  do
    echo "Waiting for deployment $i"
    oc rollout status deployment --timeout=2m "$i" -n ${ARGO_NS} >/dev/null 2>&1 || true
  done

  echo
  echo "OpenShift GitOps successfully installed."
}

install_gitops(){
  echo
  echo "Installing GitOps Operator."

  # kustomize build components/operators/openshift-gitops-operator/operator/overlays/stable | oc apply -f -
  oc apply -k "components/operators/openshift-gitops-operator/operator/overlays/${ARGO_CHANNEL}"

  echo "Pause ${SLEEP_SECONDS} seconds for the creation of the gitops-operator..."
  sleep ${SLEEP_SECONDS}

  wait_for_gitops

}

select_bootstrap_folder(){
  PS3="Please select a bootstrap folder by number: "
  
  echo
  select bootstrap_dir in bootstrap/overlays/*/
  do
      test -n "$bootstrap_dir" && break
      echo ">>> Invalid Selection <<<";
  done

  bootstrap_cluster
}

bootstrap_cluster(){

  if [ -n "$bootstrap_dir" ]; then
    echo "Selected: ${bootstrap_dir}"
  else
    select_bootstrap_folder
  fi

  # kustomize build "${bootstrap_dir}" | oc apply -f -
  oc apply -k "${bootstrap_dir}"

  wait_for_gitops

  echo
  echo "GitOps has successfully deployed!  Check the status of the sync here:"

  route=$(oc get route openshift-gitops-server -o jsonpath='{.spec.host}' -n ${ARGO_NS})

  echo "https://${route}"
}

# kludge: rhdp setup
post_bootstrap(){
  [ -n "${EDGE_WORKSHOP}" ] || return

  [ ! -e scratch ] && mkdir scratch
  cd scratch

  git clone https://github.com/Enterprise-Neurosystem/edge-failure-prediction.git
  cd edge-failure-prediction
  scripts/bootstrap.sh
  cd ..

  git clone https://github.com/Enterprise-Neurosystem/edge-anomaly-detection.git
  cd edge-anomaly-detection
  scripts/bootstrap.sh
  cd ..
  
  cd ..

  ocp_control_dedicated
  ocp_create_machineset_autoscale 0 30
  # ocp_scale_all_machineset 2
}

# functions
setup_bin
check_bin oc
# check_bin kustomize
# check_bin kubeseal
check_oc_login

# bootstrap
# sealed_secret_check
install_gitops
bootstrap_cluster
post_bootstrap
