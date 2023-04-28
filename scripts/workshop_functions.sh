#!/bin/bash

W_USER=${W_USER:-user}
W_PASS=${W_PASS:-ThisIsFine}
GROUP_ADMINS=workshop-admins
GROUP_USERS=workshop-users
HTPASSWD=htpasswd-workshop-secret
TMP_DIR=scratch
WORKSHOP_USERS=25

usage(){
  echo "Workshop: Functions Loaded"
  echo ""
  echo "usage: workshop_[setup,reset,clean]"
}

doing_it_wrong(){
  echo "usage: source scripts/workshop-functions.sh"
}

is_sourced() {
  if [ -n "$ZSH_VERSION" ]; then
      case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
      case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1  # NOT sourced.
}

check_init(){
  # do you have oc
  which oc > /dev/null || exit 1

  # create generated folder
  [ ! -d ${TMP_DIR} ] && mkdir -p ${TMP_DIR}
}

workshop_create_user_htpasswd(){
  FILE=${TMP_DIR}/htpasswd
  touch ${FILE}

  which htpasswd || return

  for i in {0..25}
  do
    htpasswd -bB ${FILE} "${W_USER}${i}" "${W_PASS}${i}"
  done

  oc -n openshift-config create secret generic ${HTPASSWD} --from-file=${FILE}
  oc -n openshift-config set data secret/${HTPASSWD} --from-file=${FILE}

}

workshop_create_user_ns(){
  OBJ_DIR=${TMP_DIR}/users
  [ -e ${OBJ_DIR} ] && rm -rf ${OBJ_DIR}
  [ ! -d ${OBJ_DIR} ] && mkdir -p ${OBJ_DIR}

  for i in {0..25}
  do
    # create ns
    oc -o yaml --dry-run=client \
      create ns "${W_USER}${i}" > "${OBJ_DIR}/${W_USER}${i}-ns.yml"
    oc apply -f "${OBJ_DIR}/${W_USER}${i}-ns.yml"

    # create role binding - admin for user
    oc -o yaml --dry-run=client \
      -n "${W_USER}${i}" \
      create rolebinding "${W_USER}${i}-admin" \
      --group "${GROUP_ADMINS}" \
      --user "${W_USER}${i}" \
      --clusterrole admin > "${OBJ_DIR}/${W_USER}${i}-ns-admin-rb.yml"

    # create role binding - view for workshop group
    oc -o yaml --dry-run=client \
      -n "${W_USER}${i}" \
      create rolebinding "${W_USER}${i}-view" \
      --group "${GROUP_USERS}" \
      --clusterrole view > "${OBJ_DIR}/${W_USER}${i}-rb-ns-view.yml"
  done

  # apply objects created in scratch dir
    oc apply -f ${OBJ_DIR}
 }

workshop_clean_user_ns(){
  for i in {0..25}
  do
    oc delete project "${W_USER}${i}"
  done
}

workshop_clean_user_notebooks(){
  oc -n rhods-notebooks \
    delete po -l app=jupyterhub
}

workshop_setup(){
  check_init
  workshop_create_user_htpasswd
  workshop_create_user_ns
}

workshop_clean(){
  echo "Workshop: Clean User Namespaces"
  check_init
  workshop_clean_user_ns
  workshop_clean_user_notebooks
}

workshop_reset(){
  echo "Workshop: Reset"
  check_init
  workshop_clean
  sleep 8
  workshop_setup
}

is_sourced && usage
is_sourced || doing_it_wrong
