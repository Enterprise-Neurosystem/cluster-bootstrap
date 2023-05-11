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
  APPS_INGRESS=apps.cluster-cfzzs.sandbox1911.opentlc.com
  NOTEBOOK_IMAGE_NAME=s2i-minimal-notebook:1.2

  for i in {1..50}
  do

      NB_USER="user${i}"

echo "---
apiVersion: kubeflow.org/v1
kind: Notebook
metadata:
  annotations:
    notebooks.opendatahub.io/inject-oauth: 'true'
    notebooks.opendatahub.io/last-image-selection: '${NOTEBOOK_IMAGE_NAME}'
    notebooks.opendatahub.io/last-size-selection: Demo / Workshop
    notebooks.opendatahub.io/oauth-logout-url: >-
      https://rhods-dashboard-redhat-ods-applications.${APPS_INGRESS}/notebookController/${NB_USER}/home
    opendatahub.io/link: >-
      https://jupyter-nb-${NB_USER}-rhods-notebooks.${APPS_INGRESS}/notebook/rhods-notebooks/jupyter-nb-${NB_USER}
    opendatahub.io/username: ${NB_USER}
  name: jupyter-nb-${NB_USER}
  namespace: rhods-notebooks
  labels:
    app: jupyter-nb-${NB_USER}
    opendatahub.io/dashboard: 'true'
    opendatahub.io/odh-managed: 'true'
    opendatahub.io/user: ${NB_USER}
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
              memory: 16Gi
            requests:
              cpu: '3'
              memory: 16Gi
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /notebook/rhods-notebooks/jupyter-nb-${NB_USER}/api
              port: notebook-port
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
          name: jupyter-nb-${NB_USER}
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /notebook/rhods-notebooks/jupyter-nb-${NB_USER}/api
              port: notebook-port
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
          env:
            - name: NOTEBOOK_ARGS
              value: |-
                --ServerApp.port=8888
                --ServerApp.token=''
                --ServerApp.password=''
                --ServerApp.base_url=/notebook/rhods-notebooks/jupyter-nb-${NB_USER}
                --ServerApp.quit_button=False
                --ServerApp.tornado_settings={\"user\":\"${NB_USER}\",\"hub_host\":\"https://rhods-dashboard-redhat-ods-applications.${APPS_INGRESS}\",\"hub_prefix\":\"/notebookController/${NB_USER}\"}
            - name: JUPYTER_IMAGE
              value: >-
                image-registry.openshift-image-registry.svc:5000/redhat-ods-applications/${NOTEBOOK_IMAGE_NAME}
            - name: JUPYTER_NOTEBOOK_PORT
              value: '8888'
          ports:
            - containerPort: 8888
              name: notebook-port
              protocol: TCP
          imagePullPolicy: Always
          volumeMounts:
            - mountPath: /opt/app-root/src
              name: jupyterhub-nb-${NB_USER}-pvc
          image: >-
            image-registry.openshift-image-registry.svc:5000/redhat-ods-applications/${NOTEBOOK_IMAGE_NAME}
          workingDir: /opt/app-root/src
        - resources:
            limits:
              cpu: 100m
              memory: 64Mi
            requests:
              cpu: 100m
              memory: 64Mi
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /oauth/healthz
              port: oauth-proxy
              scheme: HTTPS
            initialDelaySeconds: 5
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
          name: oauth-proxy
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /oauth/healthz
              port: oauth-proxy
              scheme: HTTPS
            initialDelaySeconds: 30
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
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
          args:
            - '--provider=openshift'
            - '--https-address=:8443'
            - '--http-address='
            - '--openshift-service-account=jupyter-nb-${NB_USER}'
            - '--cookie-secret-file=/etc/oauth/config/cookie_secret'
            - '--cookie-expire=24h0m0s'
            - '--tls-cert=/etc/tls/private/tls.crt'
            - '--tls-key=/etc/tls/private/tls.key'
            - '--upstream=http://localhost:8888'
            - '--upstream-ca=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
            - '--email-domain=*'
            - '--skip-provider-button'
            - >-
              --openshift-sar={\"verb\":\"get\",\"resource\":\"notebooks\",\"resourceAPIGroup\":\"kubeflow.org\",\"resourceName\":\"jupyter-nb-${NB_USER}\",\"namespace\":\"\$(NAMESPACE)\"}
            - >-
              --logout-url=https://rhods-dashboard-redhat-ods-applications.${APPS_INGRESS}/notebookController/${NB_USER}/home
      enableServiceLinks: false
      serviceAccountName: jupyter-nb-${NB_USER}
      volumes:
        - name: jupyterhub-nb-${NB_USER}-pvc
          persistentVolumeClaim:
            claimName: jupyterhub-nb-${NB_USER}-pvc
        - name: oauth-config
          secret:
            defaultMode: 420
            secretName: jupyter-nb-${NB_USER}-oauth-config
        - name: tls-certificates
          secret:
            defaultMode: 420
            secretName: jupyter-nb-${NB_USER}-tls
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  annotations:
  name: jupyterhub-nb-${NB_USER}-pvc
  namespace: rhods-notebooks
  labels:
    opendatahub.io/dashboard: 'true'
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  volumeMode: Filesystem
" #| oc apply -f -
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
