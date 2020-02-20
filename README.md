# Kubernetes Generic Helm Chart

This Helm Chart can be used to deploy your application container under a [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) or [CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) resource onto your Kubernetes cluster. You can use this Helm Chart to run and deploy a long-running container, such as a web service or backend microservice. The container will be packaged into [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) that are managed by the `Deployment` controller.

This Helm Chart can also be used to front the `Pods` of the `Deployment` resource with a [Service](https://kubernetes.io/docs/concepts/services-networking/service/) to provide a stable endpoint to access the `Pods`.

## How to use this chart?

* Look in to the examples [folder](./examples) for example usage.
* See the provided [values.yaml](./values.yaml) file for the required and optional configuration values that you can set on this chart.

## What resources does this Helm Chart deploy?

The following resources will be deployed with this Helm Chart, depending on which configuration values you use:

- `Deployment`: The main `Deployment` controller that will manage the application container image specified in the `containerImage` input value.
- `CronJob`: The `CronJob` resource creates Jobs on a time-based schedule. Created only if you configure the `schedule` timer.
- `Service`: The `Service` resource providing a stable endpoint that can be used to address to `Pods` created by the `Deployment` controller. Created only if you configure the `service` input (and set`service.enabled = true`).
- `ConfigMap`: `ConfigMaps` allow you to decouple configuration artifacts from image content to keep containerized applications portable. Created only if you configure the `configMaps` input.
- `Secret`: The `secrets` object let you store and manage sensitive information, such as passwords, OAuth tokens, and ssh keys. Putting this information in a `secret` is safer and more flexible than putting it verbatim in a Pod definition or in a container image. Created only if you configure the `secrets` input.
- `ServiceAccount`: A `ServiceAccount` provides an identity for processes that run in a Pod.
- `ClusterRole`:  The `Role-based access control (RBAC)` is a method of regulating access to computer or network resources based on the roles of individual users within an enterprise. Created only if you configure the `rbac` input (and set`rbac.create = true`).
- `ClusterRoleBinding`: A `ClusterRoleBinding` grants the permissions defined in a `rbac` to the ServiceAccount. Created only if you configure the `rbac` input (and set`rbac.create = true`).

## How to deploy and update the application to a new version?

Suppose you are deploying `nginx` version 1.15.4 using this Helm Chart with the following values:

```yaml
name: nginx

containerImage:
  repository: nginx
  tag: 1.15.4
```

In this example, we will assume that you are deploying this chart with the above values using the release name
`some-service`, using a command similar to below:

```bash
helm install -f values.yaml --name some-service ./
```

Now let's try upgrading `nginx` to version 1.15.8. To do so, we will first update our values file:

```yaml
name: nginx

containerImage:
  repository: nginx
  tag: 1.15.8
```

The only difference here is the `tag` of the `containerImage`.

Next, we will upgrade our release using the updated values. To do so, we will use the `helm upgrade` command:

```bash
helm upgrade -f values.yaml some-service ./
```

This will update the created resources with the new values provided by the updated `values.yaml` file. For this example,
the only resource that will be updated is the `Deployment` resource, which will now have a new `Pod` spec that points to
`nginx:1.15.8` as opposed to `nginx:1.15.4`. This automatically triggers a rolling deployment internally to Kubernetes,
which will launch new `Pods` using the latest image, and shut down old `Pods` once those are ready.

You can read more about how changes are rolled out on `Deployment` resources in [the official
documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment).

Note that certain changes will lead to a replacement of the `Deployment` resource. For example, updating the
`name` value will cause the `Deployment` resource to be deleted, and then created. This can lead to down time
because the resources are replaced in an uncontrolled fashion.

## How to use this generic chart in GitLab CI/CD pipeline?

1. Create a repository in Gitlab.
2. Create *.gitlab-ci.yml* file with below content and update with propper values e.g. NAMESPACE, tags, image and release name.
```yaml
variables:
  NAMESPACE: kris

stages:
  - Helm dry-run
  - Helm deployment

before_script:
  - helm init --client-only
  - helm init --dry-run &> /dev/null && helm init --client-only

image:
    name: docker.io/kskrisss/helm-generic-chart:latest

.template: &tags
  tags:
    - k8s-tools3

# ----------- some-service -----------------------------------------------------------
some-service_dry_run:
  <<: *tags
  stage: Helm dry-run
  script:
    - helm upgrade -i --force some-service /generic-chart -f values.yaml --dry-run

some-service_deploy:
  <<: *tags
  stage: Helm deployment
  when: manual
  script:
    - helm upgrade -i --force some-service /generic-chart -f values.yaml
  only:
  - master
```
3. Create your values.yaml file e.g.:
```yaml
name: nginx-generic-chart
containerImage:
  repository: nginx
  tag: 1.17.8
```
5. Run your deployment in Gitlab CI/CD Pipeline if dry-run finished successfully.
6. Done

