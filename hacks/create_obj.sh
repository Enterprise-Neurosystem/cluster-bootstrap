#!/bin/sh

USER=user
PASS=ThisIsFine
GROUP=workshop-attendees
TMP_DIR=generated

PGAMDIN_NS=db-veiwer

check_path(){
    mkdir -p ${TMP_DIR}
}

create_htpasswd(){
    FILE=${TMP_DIR}/htpasswd

    touch ${FILE}
    for i in {01..20}
    do
        htpasswd -bB ${FILE} ${USER}${i} ${PASS}${i}
    done

    oc -n openshift-config create secret generic workshop-htpasswd --from-file=${FILE}
    oc -n openshift-config set data secret/workshop-htpasswd --from-file=${FILE}

}

create_ns(){

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

    oc create ns ${NS}

    oc -n ${PGAMDIN_NS} \
    new-app \
    --image docker.io/dpage/pgadmin4 \
    --name ${NAME} \
    PGADMIN_DEFAULT_EMAIL=user@example.com \
    PGADMIN_DEFAULT_PASSWORD=ThisIsFine

    oc expose service/${NAME}

}

clean_ns(){
    for i in {01..20}
    do
        oc delete project ${USER}${i}
    done

    oc delete ns ${PGAMDIN_NS}
}

check_path
create_htpasswd
create_ns
#create_pgadmin

#clean_ns