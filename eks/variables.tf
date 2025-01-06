variable "AWS_region" {
  default     = "us-east-1"
  description = "AWS region"
}

variable "AWS_profile" {
  default     = "default"
  description = "AWS authorization profile"
}

// Kinesis stream for ingesting the textual data from
variable "stream_name" {
  default     = "sentiment-source-stream"
  description = "Kinesis stream to read the data from"
}

variable "shards" {
  default     = 2
  description = "Number of Kinesis stream shards"
}

// Checkpoint location for Spark streaming on S3
variable "checkpoint_bucket" {
  default     = "spark-sentiment-analysis"
  description = "Checkpoint bucket name"
}

// EKS specific parameters: Executors
variable "executors_ami_type" {
  default     = "AL2023_ARM_64_STANDARD"
  description = "Executors AMI type"
}

variable "executors_instance_types" {
  default     = ["r7g.4xlarge"]
  description = "Executors instance types"
}

variable "executors_max_size" {
  default     = 5
  description = "Maximum number of executor nodes"
}

variable "executors_desired_size" {
  default     = 3
  description = "Desired number of executor nodes"
}

// EKS specific parameters: Prometheus
variable "prometheus_ami_type" {
  default     = "AL2023_ARM_64_STANDARD"
  description = "Prometheus AMI type"
}

variable "prometheus_instance_types" {
  default     = ["r7g.4xlarge"]
  description = "Prometheus instance types"
}

variable "prometheus_max_size" {
  default     = 1
  description = "maximum number of prometheus nodes"
}

variable "prometheus_desired_size" {
  default     = 1
  description = "Desired number of prometheus nodes"
}

# Prometheus
variable "settings_prometheus" {
  // TODO: do we need all the following node selectors?
  // https://github.com/prometheus-community/helm-charts/blob/kube-prometheus-stack-66.1.1/charts/kube-prometheus-stack/values.yaml
  default = {
    alertmanager = {
      alertmanagerSpec = {
        nodeSelector = {
          environment = "prometheus"
        }
      }
    }

    prometheusOperator = {
      nodeSelector = {
        environment = "prometheus"
      }
    }

    prometheus = {
      prometheusSpec = {
        nodeSelector = {
          environment = "prometheus"
        }
      }
    }

    kube-state-metrics = {
      nodeSelector = {
        environment = "prometheus"
      }
    }

    grafana = {
      nodeSelector = {
        environment = "prometheus"
      }
    }

  }
  description = "Settings for Prometheus Helm chart components."
}
