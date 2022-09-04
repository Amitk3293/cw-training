provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "cert-manager" {
  name              = "cert-manager"
  repository        = "https://charts.bitnami.com/bitnami"
  chart             = "cert-manager"
  namespace         = var.namespace
  create_namespace  = var.create_namespace
  dependency_update = true
  values            = [file("./helm-prov-tf/cert-manager/certmanager-values.yaml")]


  provisioner "local-exec" {
    command = <<EOF
      echo "Waiting for the cert-manager pods" \
      kubectl wait --namespace cert-manager \
      --for=condition=ready pod \
      --timeout=120s
      echo "cert-manager successfully started"
    EOF

  }
}