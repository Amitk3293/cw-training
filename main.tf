# module "helm-certmanager" {
#   source = "./helm-prov-tf/cert-manager"

# }

# module "helm-mysql" {
#   source = "./helm-prov-tf/mysql"

# }

module "helm-argocd" {
  source = "./helm-prov-tf/argocd"

}