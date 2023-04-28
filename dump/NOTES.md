# Notes Dump

## Issues

OCP: 4.10.55
RHODS: 1.24.0

https://issues.redhat.com/projects/RHODS/issues/RHODS-8000?filter=allissues

Issue: Operator install failed

Init container logs

```
kfdef.kfdef.apps.kubeflow.org/rhods-anaconda unchanged
secret/anaconda-ce-access unchanged
INFO: Applying specific configuration for self-managed environments.
Creating Serving Runtime resources...
error: error executing jsonpath "{.items[-1].spec.install.spec.deployments[?(@.name == \"rhods-operator\")].spec.template.spec.containers[?(@.name == \"rhods-operator\")].env[?(@.name == \"RELATED_IMAGE_ODH_OPENVINO_IMAGE\")].value}": Error executing template: array index out of bounds: index -1, length 0. Printing more information for debugging the template:
template was:
{.items[-1].spec.install.spec.deployments[?(@.name == "rhods-operator")].spec.template.spec.containers[?(@.name == "rhods-operator")].env[?(@.name == "RELATED_IMAGE_ODH_OPENVINO_IMAGE")].value}
object given to jsonpath engine was:
map[string]interface {}{"apiVersion":"v1", "items":[]interface {}{}, "kind":"List", "metadata":map[string]interface {}{"resourceVersion":"", "selfLink":""}}
```
