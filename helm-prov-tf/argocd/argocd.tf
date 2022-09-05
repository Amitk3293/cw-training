provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "argo-cd" {
  name              = "argo-cd"
  repository        = "https://argoproj.github.io/argo-helm"
  chart             = "argo-cd"
  namespace         = var.namespace
  create_namespace  = var.create_namespace
  dependency_update = true
  values            = [file("./helm-prov-tf/argocd/argo-values.yaml")]


  provisioner "local-exec" {
    command = <<EOF
      echo "Waiting for the argo-cd pods" \
      kubectl wait --namespace argo-cd \
      --for=condition=ready pod \
      --timeout=120s
      echo "argo-cd successfully started"
    EOF

  }
  provisioner "local-exec" {
    command = <<EOF
      echo "Here's your argo password " \
      $(kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    EOF
  }

    # provisioner "local-exec" {
    # command = <<EOF
    #   echo $(pwd) \
    #   $(kubectl apply -f ./applicationsets/deploy-example.yaml)
    # EOF
# }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
resource "kubernetes_manifest" "applicationset_argocd" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind" = "ApplicationSet"
    "metadata" = {
      "name" = "argo-infra-appset"
      "namespace" = "argo-cd"
    }
    "spec" = {
      "generators" = [
        {
          "list" = {
            "elements" = [
              {
                "appName" = "prometheus"
                "namespace" = "monitoring"
              },
              {
                "appName" = "rabbitmq"
                "namespace" = "rabbitmq"
              },
            ]
          }
        },
      ]
      "template" = {
        "metadata" = {
          "annotations" = {
            "argocd.argoproj.io/manifest-generate-paths" = ".;.."
          }
          "name" = "{{appName}}"
        }
        "spec" = {
          "destination" = {
            "name" = "in-cluster"
            "namespace" = "{{namespace}}"
          }
          "project" = "default"
          "source" = {
            "helm" = {
              "releaseName" = "{{appName}}"
              "valueFiles" = [
                "values.yaml",
              ]
            }
            "path" = "applicationsets/infra/{{appName}}"
            "repoURL" = "https://github.com/Amitk3293/cw-training.git"
            "targetRevision" = "HEAD"
          }
          "syncPolicy" = {
            "automated" = {
              "prune" = true
              "selfHeal" = true
            }
            "syncOptions" = [
              "CreateNamespace=true",
            ]
          }
        }
      }
    }
  }
}