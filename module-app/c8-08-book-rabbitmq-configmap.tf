 # Resource: Config Map
 resource "kubernetes_config_map_v1" "book_rabbitmq_config_map" {
   metadata {
     name = "book-rabbitmq-dbcreation-script"
   }
   data = {
    "book-rabbitmq.conf" = "${file("${path.module}/init-conf/book-rabbitmq.conf")}"
   }
 }