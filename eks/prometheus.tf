// https://github.com/DNXLabs/terraform-aws-eks-grafana-prometheus/tree/master

resource "helm_release" "prometheus" {
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
