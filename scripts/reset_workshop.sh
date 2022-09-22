#!/bin/bash

source $(dirname $0)/workshop.sh

USER=user
PASS=WorkshopPassword

echo "Workshop: Clean User Namespaces"

check_init

clean_user_notebooks
clean_user_ns

create_user_ns
