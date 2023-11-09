resource "kubernetes_config_map_v1" "catalog" {
  metadata {
    name      = "catalog"
    labels = {
      app = "catalog"
    }
  }

  data = {
    "application.yml" = file("${path.module}/app-conf/catalog.yml")
  }
}

resource "kubernetes_deployment_v1" "catalog_deployment" {
  depends_on = [kubernetes_deployment_v1.book_postgres_deployment]
  metadata {
    name = "catalog"
    labels = {
      app = "catalog"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "catalog"
      }
    }
    template {
      metadata {
        labels = {
          app = "catalog"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "8080"
        }        
      }
      spec {
        service_account_name = "spring-cloud-kubernetes"      
        
        container {
          image = "ghcr.io/greeta-bookshop-01/catalog-service:ce144e6ea80cefa03c6d07cd20c655bd779a33b9"
          name  = "catalog"
          image_pull_policy = "Always"
          port {
            container_port = 8080
          }  
          port {
            container_port = 8001
          } 

          env {
            name  = "SPRING_CLOUD_BOOTSTRAP_ENABLED"
            value = "true"
          }

          env {
            name  = "SPRING_CLOUD_KUBERNETES_SECRETS_ENABLEAPI"
            value = "true"
          }

          env {
            name  = "JAVA_TOOL_OPTIONS"
            value = "-javaagent:/workspace/BOOT-INF/lib/opentelemetry-javaagent-1.17.0.jar"
          }

          env {
            name  = "OTEL_SERVICE_NAME"
            value = "catalog"
          }

          env {
            name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
            value = "http://tempo.observability-stack.svc.cluster.local:4317"
          }

          env {
            name  = "OTEL_METRICS_EXPORTER"
            value = "none"
          }

          env {
            name  = "BPL_JVM_THREAD_COUNT"
            value = "50"
          }

          env {
            name  = "BPL_DEBUG_ENABLED"
            value = "true"
          }

          env {
            name  = "BPL_DEBUG_PORT"
            value = "8001"
          }       
          

          # resources {
          #   requests = {
          #     memory = "756Mi"
          #     cpu    = "0.1"
          #   }
          #   limits = {
          #     memory = "756Mi"
          #     cpu    = "2"
          #   }
          # }          

          lifecycle {
            pre_stop {
              exec {
                command = ["sh", "-c", "sleep 5"]
              }
            }
          }

          # liveness_probe {
          #   http_get {
          #     path = "/actuator/health/liveness"
          #     port = 8080
          #   }
          #   initial_delay_seconds = 120
          #   period_seconds        = 15
          # }

          # readiness_probe {
          #   http_get {
          #     path = "/actuator/health/readiness"
          #     port = 8080
          #   }
          #   initial_delay_seconds = 20
          #   period_seconds        = 15
          # }  
         
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "catalog_hpa" {
  metadata {
    name = "catalog-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.catalog_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 70
  }
}

resource "kubernetes_service_v1" "catalog_service" {
  depends_on = [kubernetes_deployment_v1.catalog_deployment]
  metadata {
    name = "catalog"
    labels = {
      app = "catalog"
      spring-boot = "true"
    }
  }
  spec {
    selector = {
      app = "catalog"
    }
    port {
      name = "prod"
      port = 8080
    }
    port {
      name = "debug"
      port = 8001
    }    
  }
}