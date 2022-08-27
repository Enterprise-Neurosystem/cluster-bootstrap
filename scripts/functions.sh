#!/bin/bash

USER=user
PASS=WorkshopPassword
GROUP=workshop-attendees
TMP_DIR=generated

PGAMDIN_NS=db-viewer

check_init(){
    # do you have oc
    which oc > /dev/null || exit 1

    # create generated folder
    [ ! -d ${TMP_DIR} ] && mkdir -p ${TMP_DIR}
}

create_user_htpasswd(){
    FILE=${TMP_DIR}/htpasswd

    touch ${FILE}
    for i in {01..20}
    do
        htpasswd -bB ${FILE} ${USER}${i} ${PASS}${i}
    done

    oc -n openshift-config create secret generic workshop-htpasswd --from-file=${FILE}
    oc -n openshift-config set data secret/workshop-htpasswd --from-file=${FILE}

}

create_user_ns(){

    for i in {01..20}
    do
        oc -o yaml --dry-run=client \
          create ns ${USER}${i} > ${TMP_DIR}/ns-${USER}${i}.yml
        oc -o yaml --dry-run=client \
          create rolebinding ${USER}${i}-admin -n ${USER}${i} --user ${USER}${i} --clusterrole admin > ${TMP_DIR}/rb-ns-${USER}${i}-admin.yml
        oc -o yaml --dry-run=client \
          create rolebinding ${USER}${i}-view -n ${USER}${i} --group ${GROUP} --clusterrole view > ${TMP_DIR}/rb-ns-${USER}${i}-view.yml
    done
}

create_pgadmin(){
    NAME=pgadmin4

    oc create ns ${PGAMDIN_NS}

    oc -n ${PGAMDIN_NS} \
        new-app \
        --image docker.io/dpage/pgadmin4 \
        --name ${NAME} \
        PGADMIN_DEFAULT_EMAIL=user@example.com \
        PGADMIN_DEFAULT_PASSWORD=${PASS}

    oc -n ${PGAMDIN_NS} \
        expose service/${NAME}

    #oc -n ${PGAMDIN_NS} \
    #    set volume deploy/${NAME} \
    #    --add --name=pgadmin4-volume-1 \
    #    -t pvc --claim-size=512M \
    #    --claim-name=${NAME}-pvc --overwrite


}

clean_user_ns(){
    for i in {01..20}
    do
        oc delete project ${USER}${i}
    done

}

clean_other_ns(){
    oc delete ns ${PGAMDIN_NS}
    oc -n rhods-notebooks \
        delete po -l app=jupyterhub
}

echo "Workshop: Functions Loaded"