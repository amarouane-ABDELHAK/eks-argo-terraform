provider "aws" {
  region = "us-west-2"
}


locals {
  policies = ["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy", "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]
}


resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main-eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private_subnet.*.id  # Deploy worker nodes in private subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  tags = {
    Name = "main-eks-node-group"
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "eks-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "eks-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_role_attachment" {
  for_each   = toset(local.policies)
  role       = aws_iam_role.eks_node_role.name
  policy_arn = each.value
}
