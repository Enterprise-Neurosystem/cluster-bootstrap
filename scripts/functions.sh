#!/bin/bash

USER=user
PASS=WorkshopPassword
GROUP=workshop-attendees
TMP_DIR=generated

check_init(){
    # do you have oc
    which oc > /dev/null || exit 1

    # create generated folder
    [ ! -d ${TMP_DIR} ] && mkdir -p ${TMP_DIR}
}

create_user_htpasswd(){
    FILE=${TMP_DIR}/htpasswd
    touch ${FILE}

    which htpasswd || return

    for i in {01..20}
    do
        htpasswd -bB ${FILE} ${USER}${i} ${PASS}${i}
    done

    oc -n openshift-config create secret generic workshop-htpasswd --from-file=${FILE}
    oc -n openshift-config set data secret/workshop-htpasswd --from-file=${FILE}

}

create_user_ns(){
    OBJ_DIR=${TMP_DIR}/users
    [ ! -d ${OBJ_DIR} ] && mkdir -p ${OBJ_DIR}

    for i in {01..20}
    do
        # create ns
        oc -o yaml --dry-run=client \
          create ns ${USER}${i} > ${OBJ_DIR}/ns-${USER}${i}.yml

        # create role binding - admin for user
        oc -o yaml --dry-run=client \
          -n ${USER}${i} \
          create rolebinding ${USER}${i}-admin \
          --user ${USER}${i} \
          --clusterrole admin > ${OBJ_DIR}/rb-ns-${USER}${i}-admin.yml

        # create role binding - view for workshop group
        oc -o yaml --dry-run=client \
          -n ${USER}${i} \
          create rolebinding ${USER}${i}-view \
          --group ${GROUP} \
          --clusterrole view > ${OBJ_DIR}/rb-ns-${USER}${i}-view.yml
    done

    # apply objects created in scratch dir
    oc apply -f ${OBJ_DIR}
}

create_pgadmin(){
    APP_NAME=pgadmin4
    APP_NS=${APP_NAME}

    OBJ_DIR=${TMP_DIR}/${APP_NAME}
    [ ! -d ${OBJ_DIR} ] && mkdir -p ${OBJ_DIR}

    oc create ns ${APP_NS}

    oc -n ${APP_NS} \
        new-app \
        --image docker.io/dpage/pgadmin4 \
        --name ${APP_NAME} \
        PGADMIN_DEFAULT_EMAIL=user@example.com \
        PGADMIN_DEFAULT_PASSWORD=${PASS}

    oc -n ${APP_NS} \
        expose service/${APP_NAME}

    oc -n ${APP_NS} \
       set volume deploy/${APP_NAME} \
       --add --name=pgadmin4-volume-1 \
       -t pvc --claim-size=512M \
       --claim-name=${APP_NAME}-pvc --overwrite


}

clean_user_notebooks(){
    oc -n rhods-notebooks \
        delete po -l app=jupyterhub
}

clean_user_ns(){
    for i in {01..20}
    do
        oc delete project ${USER}${i}
    done
}

clean_other_ns(){
    oc delete ns ${APP_NS}
}


echo "Workshop: Functions Loaded"