#!/bin/bash

USER=user
PASS=WorkshopPassword
GROUP=workshop-attendees
TMP_DIR=generated

PGAMDIN_NS=db-viewer

echo "Workshop: Start Setup"

check_init
create_user_htpasswd
create_user_ns
create_pgadmin

#clean_user_ns