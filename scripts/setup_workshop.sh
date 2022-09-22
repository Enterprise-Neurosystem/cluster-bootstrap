#!/bin/bash

source "$(dirname $0)/workshop.sh"

USER=user
PASS=WorkshopPassword

echo "Workshop: Start Setup"

check_init

create_user_htpasswd
create_user_ns

create_pgadmin