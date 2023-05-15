# Red Hat Demo Platform (RHDP) Info

The following is info related to the demo environment and workshops elements.

- instance: m5.4xlarge
- cpu: 16
- memory: 62G + 2G (core services)
- users per node: 3-6
- max nodes: 20

## RHDP Scripts

Cluster Deployment

Note: This is already run for the event in RHDP

```
bash scripts/bootstrap.sh ocp4-workshop-aiml-edge
```

Post Cluster Deployment

```
git clone https://github.com/Enterprise-Neurosystem/edge-failure-prediction.git
cd edge-failure-prediction
scripts/bootstrap.sh
cd ..

git clone https://github.com/Enterprise-Neurosystem/edge-anomaly-detection.git
cd edge-anomaly-detection
scripts/bootstrap.sh
cd ..
```

Load Testing

```
. scripts/workshop_functions

# start load test
workshop_load_test
sleep 400

# remove load test
workshop_load_test_clean
```

## Links

- https://github.com/rhpds/agnosticv/tree/master/sandboxes-gpte/OCP4_WORKSHOP_AIML_EDGE
- https://github.com/redhat-gpte-devopsautomation/bookbag-edge
- https://github.com/openshift-homeroom
