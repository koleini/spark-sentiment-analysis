data "aws_availability_zones" "available" {}

locals {
  name = "spark-k8s-cluster"

  common_tags = {
    Name    = "spark-k8s-cluster"
    Creator = "<NAME OF THE CREATOR>"
  }
}

// VPC definition
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = local.name

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = local.name
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  iam_role_permissions_boundary = "arn:aws:iam::aws:policy/PowerUserAccess"

  // TODO:
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {

    executors = {
      name           = "k8s-nodes"
      ami_type       = var.executors_ami_type
      instance_types = var.executors_instance_types

      max_size     = var.executors_max_size
      desired_size = var.executors_desired_size

      /* This value is ignored after the initial creation
           https://github.com/bryantbiggs/eks-desired-size-hack
      */
      // TODO: spin all the instances inside a placement group 

      create_iam_role          = true
      iam_role_name            = "Proj-eksWorkerRole"
      iam_role_use_name_prefix = false
      iam_role_description     = "Spark Worker Node Role"
      iam_role_additional_policies = {
        /* TODO: This IAM permission is too broad. Only grant the minimum required access, such as:
             - Read/Write access to the checkpoint bucket
             - Read access to the specific Kinesis stream
        */
        // arn: Amazon Resource Names
        // https://docs.aws.amazon.com/IAM/latest/UserGuide/reference-arns.html
        kinesis_access = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
        s3_access      = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
      }

      // run spark driver/executirs on the nodes with the following label(s)
      labels = {
        environment = "k8s"
      }

      iam_role_permissions_boundary = "arn:aws:iam::aws:policy/PowerUserAccess"
    }

    prometheus = {
      name           = "prometheus-nodes"
      ami_type       = var.prometheus_ami_type
      instance_types = var.prometheus_instance_types

      max_size     = 1
      desired_size = 1

      // TODO: is the following role needed?
      create_iam_role          = true
      iam_role_name            = "Proj-eksPrometheusRole"
      iam_role_use_name_prefix = false
      iam_role_description     = "Prometheus Node Role"

      iam_role_permissions_boundary = "arn:aws:iam::aws:policy/PowerUserAccess"

      // run Prometheus-specific services (except exporters) on the nodes with the following label(s)
      labels = {
        environment = "prometheus"
      }
    }
  }

  tags = local.common_tags
}
