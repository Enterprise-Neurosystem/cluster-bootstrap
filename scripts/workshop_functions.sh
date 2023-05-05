#!/bin/bash

W_USER=${W_USER:-user}
W_PASS=${W_PASS:-openshift}
GROUP_ADMINS=workshop-admins
# GROUP_USERS=workshop-users
TMP_DIR=scratch
# HTPASSWD=htpasswd-workshop-secret
# WORKSHOP_USERS=25

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

  for i in {1..50}
  do
    htpasswd -bB ${FILE} "${W_USER}${i}" "${W_PASS}${i}"
  done

  echo "created: ${FILE}" 
  # oc -n openshift-config create secret generic ${HTPASSWD} --from-file=${FILE}
  # oc -n openshift-config set data secret/${HTPASSWD} --from-file=${FILE}

}

workshop_create_user_ns(){
  OBJ_DIR=${TMP_DIR}/users
  [ -e ${OBJ_DIR} ] && rm -rf ${OBJ_DIR}
  [ ! -d ${OBJ_DIR} ] && mkdir -p ${OBJ_DIR}

  for i in {1..50}
  do

# create ns
cat << YAML >> "${OBJ_DIR}/namespace.yaml"
---
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    openshift.io/display-name: Start Here - ${W_USER}${i}
  name: ${W_USER}${i}
YAML

# create rolebinding
cat << YAML >> "${OBJ_DIR}/admin-rolebinding.yaml"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${W_USER}${i}-admin
  namespace: ${W_USER}${i}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: ${W_USER}${i}
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: ${GROUP_ADMINS}
YAML
  done

  # apply objects created in scratch dir
    oc apply -f ${OBJ_DIR}

}

workshop_load_test(){
  for i in {1..50}
  do

echo "---
apiVersion: kubeflow.org/v1
kind: Notebook
metadata:
  annotations:
    notebooks.opendatahub.io/inject-oauth: 'true'
    notebooks.opendatahub.io/last-image-selection: 's2i-generic-data-science-notebook:py3.9-v2'
    notebooks.opendatahub.io/last-size-selection: Workshop (custom)
    notebooks.opendatahub.io/oauth-logout-url: >-
      https://rhods-dashboard-redhat-ods-applications.apps.cluster-r8mh4.sandbox8.opentlc.com/projects/group-project?notebookLogout=${W_USER}${i}
    opendatahub.io/username: admin
    openshift.io/description: 'Load Testing'
    openshift.io/display-name: ${W_USER}${i}
  name: ${W_USER}${i}
  namespace: rhods-notebooks
  labels:
    app: ${W_USER}${i}
    opendatahub.io/dashboard: 'true'
    opendatahub.io/odh-managed: 'true'
    opendatahub.io/user: admin
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - preference:
                matchExpressions:
                  - key: nvidia.com/gpu.present
                    operator: NotIn
                    values:
                      - 'true'
              weight: 1
      containers:
        - resources:
            limits:
              cpu: '6'
              memory: 20Gi
            requests:
              cpu: '6'
              memory: 20Gi
          name: notebook
          command:
            - sh
            - -c
            - |
              cat /dev/urandom >/dev/null 2>&1
          ports:
            - containerPort: 8888
              name: notebook-port
              protocol: TCP
          volumeMounts:
            - mountPath: /opt/app-root/src
              name: notebook
          image: >-
            image-registry.openshift-image-registry.svc:5000/redhat-ods-applications/s2i-generic-data-science-notebook:py3.8-v1
          workingDir: /opt/app-root/src
        - resources:
            limits:
              cpu: 100m
              memory: 64Mi
            requests:
              cpu: 100m
              memory: 64Mi
          name: oauth-proxy
          env:
            - name: NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - containerPort: 8443
              name: oauth-proxy
              protocol: TCP
          imagePullPolicy: Always
          volumeMounts:
            - mountPath: /etc/oauth/config
              name: oauth-config
            - mountPath: /etc/tls/private
              name: tls-certificates
          image: >-
            registry.redhat.io/openshift4/ose-oauth-proxy@sha256:4bef31eb993feb6f1096b51b4876c65a6fb1f4401fee97fa4f4542b6b7c9bc46
          command:
            - sleep
            - infinity
      serviceAccountName: ${W_USER}${i}
      volumes:
        - name: notebook
          persistentVolumeClaim:
            claimName: ${W_USER}${i}
        - name: oauth-config
          emptyDir: {}
        - name: tls-certificates
          emptyDir: {}
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  annotations:
  name: ${W_USER}${i}
  namespace: rhods-notebooks
  labels:
    opendatahub.io/dashboard: 'true'
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: gp3-csi
  volumeMode: Filesystem
" | oc apply -f -
  done
}

workshop_load_test_clean(){
  oc delete notebooks.kubeflow.org --all -A
  oc -n rhods-notebooks delete pvc --all
}

workshop_clean_user_ns(){
  for i in {1..50}
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
