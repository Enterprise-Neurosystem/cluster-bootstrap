#!/bin/sh

USER=user
PASS=ThisIsFine
GROUP=workshop-attendees
TMP_DIR=generated

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
}

create_ns(){
    TYPE=ns

    for i in {01..20}
    do
        oc create -o yaml --dry-run=client ns ${USER}${i} > ${TMP_DIR}/${TYPE}-${USER}${i}.yml
        oc create -o yaml --dry-run=client rolebinding ${USER}${i}-admin -n ${USER}${i} --user ${USER}${i} --clusterrole admin > ${TMP_DIR}/rb-${TYPE}-${USER}${i}.yml
        oc create -o yaml --dry-run=client rolebinding ${USER}${i}-admin -n ${USER}${i} --group ${GROUP} --clusterrole view > ${TMP_DIR}/rb-${TYPE}-${USER}${i}-workshop.yml
    done
}

create_pgadmin(){
    NS=chaosmonkey
    NAME=pgadmin4

    #oc create ns ${NS}

    oc -n ${NS} \
    new-app \
    --image docker.io/dpage/pgadmin4 \
    --name ${NAME} \
    PGADMIN_DEFAULT_EMAIL=user@example.com \
    PGADMIN_DEFAULT_PASSWORD=ThisIsFine

    oc expose service/${NAME}

}

check_path
create_htpasswd
create_ns
#create_pgadmin