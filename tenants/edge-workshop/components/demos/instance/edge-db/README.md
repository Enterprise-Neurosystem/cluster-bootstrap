# edge-db

## Command Dump

Setup local port forwarding to database (localhost:5432)

```
oc -n edge-db \
  port-forward \
  svc/edge-db 5432:5432
```

Copy files to container

```
oc cp db.sql edge-db-0:/tmp
oc cp sensor.csv.zip edge-db-0:/tmp

oc rsh edge-db-0
```

Import data in container

```
cat << EOL | oc exec edge-db-0 -- sh -c "$(cat -)"
cd /tmp
unzip -o sensor.csv.zip
psql -d edge-db -f db.sql
EOL
```
