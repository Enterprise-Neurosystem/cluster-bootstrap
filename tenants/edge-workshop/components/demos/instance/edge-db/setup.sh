#!/bin/sh

upload_files(){
  oc cp db.sql edge-db-0:/tmp
  oc cp sensor.csv.zip edge-db-0:/tmp
}

setup_db(){
cat << EOL | oc exec edge-db-0 -- sh -c "$(cat -)"
cd /tmp

# curl url.zip > sensor.csv.zip
unzip -o sensor.csv.zip
psql -d edge-db -f db.sql
EOL
}

upload_files
setup_db
