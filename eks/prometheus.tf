// https://github.com/DNXLabs/terraform-aws-eks-grafana-prometheus/tree/master

resource "helm_release" "prometheus-" {
  depends_on = [module.eks]

  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  /* https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md
     - this chart includes Grafana with built-in dashboards
  */
  chart            = "kube-prometheus-stack"
  namespace        = "prometheus"
  create_namespace = true // create the namespace defined in the scope
  version          = "66.1.1"

  values = [
    yamlencode(var.settings_prometheus)
  ]
}

/*
  - https://docs.aws.amazon.com/eks/latest/userguide/deploy-prometheus.html

  The kube-prometheus-stack deployes "non-exporter" pods as following, without requiring any specific
    persistent storage, so everything will be in running state:

alertmanager-prometheus-kube-prometheus-alertmanager-0   2/2     Running   0          8d
prometheus-grafana-6b758d7b46-v52q2                      3/3     Running   0          8d
prometheus-kube-prometheus-operator-67866c6466-jfk4b     1/1     Running   0          8d
prometheus-kube-state-metrics-677845d566-5vxqd           1/1     Running   0          8d
prometheus-prometheus-kube-prometheus-prometheus-0       2/2     Running   0          8d

The following config installs prometheus, with the following pods:

prometheus-alertmanager-0                            0/1     Pending   0          63m
prometheus-kube-state-metrics-86969d697f-gzb2x       1/1     Running   0          63m
prometheus-prometheus-pushgateway-85b7d9fbfc-48sw8   1/1     Running   0          63m
prometheus-server-7cb6576884-vbjnz                   0/2     Pending   0          63m

and it requires persistent storage for the services, so complaints:

Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  63s   default-scheduler  0/5 nodes are available: pod has unbound immediate PersistentVolumeClaims.
      preemption: 0/5 nodes are available: 5 Preemption is not helpful for scheduling.

- TODO: how to fix it?

*/
/*
resource "helm_release" "prometheus" {
  depends_on = [module.eks]

  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  namespace        = "prometheus"
  create_namespace = true // create the namespace defined in the scope
  version          = "25.30.0"

  values = [
    yamlencode(var.settings_prometheus)
  ]
}
*/