provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "mysql" {
  name              = "mysql"
  repository        = "https://charts.bitnami.com/bitnami"
  chart             = "mysql"
  namespace         = var.namespace
  create_namespace  = var.create_namespace
  dependency_update = true
  values            = [file("./helm-prov-tf/mysql/mysql-values.yaml")]


  provisioner "local-exec" {
    command = <<EOF
      echo "Waiting for the mysql pods" \
      kubectl wait --namespace mysql \
      --for=condition=ready pod \
      --timeout=120s
      echo "mysql successfully started"
    EOF

  }
}