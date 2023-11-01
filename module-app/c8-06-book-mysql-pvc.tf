resource "kubernetes_persistent_volume_claim_v1" "init_script_pvc" {
  metadata {
    name = "init-script"
  }

  spec {  
    access_modes = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class_v1.ebs_sc.metadata.0.name 
    resources {
      requests = {
        storage = "50Mi"
      }
    }
  }
}