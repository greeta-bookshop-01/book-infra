resource "kubernetes_deployment_v1" "book_ui_deployment" {
  depends_on = [kubernetes_deployment_v1.book_deployment]
  metadata {
    name = "book-ui"
    labels = {
      app = "book-ui"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "book-ui"
      }
    }
    template {
      metadata {
        labels = {
          app = "book-ui"
        }
      }
      spec {
        container {
          image = "ghcr.io/greeta-book-01/book-ui"
          name  = "book-ui"
          image_pull_policy = "Always"
          port {
            container_port = 4200
          }                                                                                          
        }
      }
    }
  }
}

# Resource: Keycloak Server Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v1" "book_ui_hpa" {
  metadata {
    name = "book-ui-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.book_ui_deployment.metadata[0].name
    }
    target_cpu_utilization_percentage = 50
  }
}

resource "kubernetes_service_v1" "book_ui_service" {
  depends_on = [kubernetes_deployment_v1.book_ui_deployment]
  metadata {
    name = "book-ui"
  }
  spec {
    selector = {
      app = "book-ui"
    }
    port {
      port = 4200
    }
  }
}
