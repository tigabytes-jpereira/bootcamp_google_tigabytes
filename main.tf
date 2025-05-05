# Criação da instância do Cloud Spanner
resource "google_spanner_instance" "main" {
  name         = var.spanner_instance_name
  config       = var.spanner_config
  display_name = var.spanner_instance_name
  num_nodes    = 1 # Comece com 1 nó para demonstração, aumente conforme necessário
}
# Criação do banco de dados do Spanner
resource "google_spanner_database" "tarefas" {
  name     = var.spanner_database_name
  instance = google_spanner_instance.main.name
  ddl = [
    "CREATE TABLE Tarefas (id STRING(36) NOT NULL PRIMARY KEY, descricao STRING(MAX) NOT NULL, concluida BOOL NOT NULL)"
  ]
}
 #Criando um novo Cloud Storage Bucket e populando
resource "google_storage_bucket" "scclab-bkt" {
  project       = var.project
  name          = var.bucket_name
  location      = var.region
  storage_class = "STANDARD"
  versioning {
    enabled = true 
  }  
  uniform_bucket_level_access = false
}
#Realizando o upload de um arquivo
resource "google_storage_bucket_object" "default" {
 name         = "scclab-script.sh"
 source       = "~/bootcamp_google_tigabytes/scclab-script.sh"
 content_type = "text/x-shellscript"
 bucket       = google_storage_bucket.scclab-bkt.id
}
#Criando instância Memorystore for Redis
 module "memorystore" {
   source  = "terraform-google-modules/memorystore/google"
   version = "~> 14.0"

   name           = "memorystore"
   tier           = "STANDARD_HA"
   project_id     = var.project
   memory_size_gb = 1
   enable_apis    = "true"
   region         = var.region
   replica_count  = 2
   read_replicas_mode  = "READ_REPLICAS_ENABLED"
 }
# Criação da rede VPC
resource "google_compute_network" "vpc_network" {
  auto_create_subnetworks = false
  name                    = "scclab-network"
  }
# Criação da subnet Publica
resource "google_compute_subnetwork" "subnet_publica" {
  ip_cidr_range = "10.0.20.0/24"
  name          = "scclab-pubsn-frontend"
  network       = google_compute_network.vpc_network.id
  region        = var.region
}
# Criação da subnet Privada
resource "google_compute_subnetwork" "subnet_privada" {
  ip_cidr_range = "10.0.10.0/24"
  name          = "scclab-pvtsn-app"
  network       = google_compute_network.vpc_network.id
  region        = var.region
  private_ip_google_access = true
}
# Cria um endereço IP público para o NAT gateway
resource "google_compute_address" "nat_ip" {
  name   = "nat-ip-backend"
  region = var.region
}
# Cria o Cloud NAT gateway para permitir que instâncias na subnet privada acessem a internet
resource "google_compute_router" "router_nat" {
  name    = "router-nat-backend"
  network = google_compute_network.vpc_network.id
  region  = var.region
}
resource "google_compute_router_nat" "nat_config" {
  name                               = "nat-config-backend"
  router                             = google_compute_router.router_nat.name
  region                             = google_compute_router.router_nat.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_ip.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
# Regra de firewall para permitir tráfego HTTP e HTTPS de qualquer lugar para a subnet pública
resource "google_compute_firewall" "allow_http_https_frontend" {
  name    = "scclab-allow-http-https-frontend"
  network = google_compute_network.vpc_network.name
  allow {
    ports   = ["80", "443"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"] # Aplique essa tag nas instâncias de frontend
}
# Regra de firewall para permitir tráfego SSH da sua rede para ambas as subnets para administração
resource "google_compute_firewall" "allow_ssh_from_your_network" {
  name    = "scclab-allow-ssh-from-your-network"
  network = google_compute_network.vpc_network.name
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
#  source_ranges = ["35.235.240.0/20"] # Permitir acesso via IAP
}
# Regra de firewall para permitir todo o tráfego da subnet pública para a subnet privada
resource "google_compute_firewall" "allow_frontend_to_backend" {
  name    = "scclab-allow-frontend-to-backend"
  network = google_compute_network.vpc_network.name
  allow {
    ports    = ["0-65535"]
    protocol = "tcp"
  }
  direction      = "INGRESS"
  source_ranges  = [google_compute_subnetwork.subnet_publica.ip_cidr_range]
  destination_ranges = [google_compute_subnetwork.subnet_privada.ip_cidr_range]
  target_tags    = ["app-server"] # Aplique essa tag nas instâncias de backend
}
# Regra de firewall para permitir tráfego ICMP (ping) para subnet pública para diagnóstico
resource "google_compute_firewall" "allow_icmp_to_frontend" {
  name    = "scclab-allow-icmp-to-frontend"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "icmp"
  }
  direction     = "INGRESS"
  target_tags   = ["web-server"]
  source_ranges = ["0.0.0.0/0"] #Comentar para corrigir erros apontados pelo SCC
#  source_ranges = ["10.0.10.0/24"] #Permitir apenas a partir da subnet publica #Remover comentário para corrigir erros apontados pelo SCC 
}
# Regra de firewall para permitir tráfego ICMP (ping) para subnet privada para diagnóstico
resource "google_compute_firewall" "allow_icmp_to_backend" {
  name    = "scclab-allow-icmp-to-backend"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "icmp"
  }
  direction     = "INGRESS"
  target_tags   = ["app-server"]
  source_ranges = ["0.0.0.0/0"] #Comentar para corrigir erros apontados pelo SCC
#  source_ranges = ["10.0.20.0/24"] #Permitir apenas a partir da subnet publica #Remover comentário para corrigir erros apontados pelo SCC
}
# Tegra de firewall para permitir o health check do load balancer nas instâncias do frontend e backend
resource "google_compute_firewall" "allow_health_check" {
  name    = "scclab-allow-health-check"
  network = google_compute_network.vpc_network.name
  allow {
    ports    = ["80"] # Assumindo que sua aplicação backend responde na porta 80
    protocol = "tcp"
  }
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # Ranges de IP do health checker do GCP
  target_tags   = ["web-server", "app-server"]
}
#Criando a Instance Template das VMs de Frontend
resource "google_compute_instance_template" "instance-template-web" {
  name_prefix  = "scclab-web-vm-"
  machine_type = "e2-micro"
  project      = var.project
  region       = var.region
  tags         = ["http-server", "web-server"]
  disk {
    source_image = "debian-cloud/debian-12"
    disk_size_gb = 10
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    subnetwork = "scclab-pubsn-frontend"
    access_config { #Comentar este bloco para corrigir erro apontado pelo SCC
      network_tier = "PREMIUM"
    }
     stack_type  = "IPV4_ONLY"
  }
#Remover comentário para corrigir erros apontados pelo SCC
#  shielded_instance_config {
#    enable_integrity_monitoring = true
#    enable_secure_boot          = true
#    enable_vtpm                 = true
#  }

  metadata = {
    enable-osconfig = "TRUE"
    startup-script  = "#!/bin/bash\nsudo wget https://github.com/tigabytes-jpereira/bootcamp_google_tigabytes/raw/refs/heads/main/app/ssclab-script-frontend.sh\nsudo chmod +x .scclab-script-frontend.sh"
  }
  
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  depends_on = [google_compute_firewall.backend_firewall]
}
resource "google_compute_instance_template" "instance-template-app" {
  name_prefix  = "scclab-app-vm-"
  machine_type = "e2-micro"
  project      = var.project
  region       = var.region
  tags         = ["http-server", "app-server"]
  disk {
    source_image = "debian-cloud/debian-12"
    disk_size_gb = 10
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    subnetwork = "scclab-pvtsn-app"
    access_config {#Comentar este bloco para corrigir erro apontado pelo SCC
      network_tier = "PREMIUM"
    }
    stack_type  = "IPV4_ONLY"
  }

#Remover comentário para corrigir erros apontados pelo SCC
#  shielded_instance_config {
#    enable_integrity_monitoring = true
#    enable_secure_boot          = true
#    enable_vtpm                 = true
#  }

  metadata = {
    enable-osconfig = "TRUE"
    startup-script  = "#!/bin/bash\nsudo wget https://github.com/tigabytes-jpereira/bootcamp_google_tigabytes/raw/refs/heads/main/app/ssclab-script-backend.sh\nsudo chmod +x .scclab-script-backend.sh"
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  depends_on = [google_compute_firewall.backend_firewall]
}
# Criação do MIG (Managed Instance Group) de Frontend
resource "google_compute_region_instance_group_manager" "mig-web" {
  name                      = "mig-web"
  region                    = var.region
  distribution_policy_zones = ["us-east1-b", "us-east1-c", "us-east1-d"] #Considerando a região de US-EAST1, preencha de acordo com a região escolhida
  target_size               = var.target_size
  base_instance_name        = "instance-template-web"
  version {
    instance_template = google_compute_instance_template.instance-template-web.self_link
  }
  depends_on = [google_compute_instance_template.instance-template-web]
}
# Criação do MIG (Managed Instance Group) de Backend
resource "google_compute_region_instance_group_manager" "mig-app" {
  name                      = "mig-app"
  region                    = var.region
  distribution_policy_zones = ["us-east1-b", "us-east1-c", "us-east1-d"] #Considerando a região de US-EAST1, preencha de acordo com a região escolhida
  target_size               = var.target_size
  base_instance_name        = "instance-template-app"
  version {
    instance_template = google_compute_instance_template.instance-template-app.self_link
  }
  depends_on = [google_compute_instance_template.instance-template-app]
}
# Criação do External Load Balancer para o Frontend
# Cria um endereço IP público para o Load Balancer do Frontend
resource "google_compute_address" "frontend_lb_ip" {
  name   = "scclab-lb-frontend-ip"
  region = var.region
}
# Cria um health check para o Load Balancer para o Frontend
resource "google_compute_health_check" "frontend_http_health_check" {
  name        = "frontend-http-health-check"
  http_health_check {
    port        = 80 # Porta em que sua aplicação frontend responde
    request_path = "/" # Endpoint para verificar a saúde
  }
}
# Cria um service para o Load Balancer para o Frontend
resource "google_compute_region_backend_service" "frontend_service" {
  name                  = "frontend-service"
  region                = var.region
  protocol              = "HTTP"
  health_checks         = [google_compute_health_check.frontend_http_health_check.id]
  load_balancing_scheme = "EXTERNAL"

  group {
    instance_group = google_compute_region_instance_group_manager.mig-web.instance_group
  }
}
# Cria um URL map para rotear as requisições para o Frontend
resource "google_compute_url_map" "frontend_http_url_map" {
  name            = "frontend-http-url-map"
  default_service = google_compute_region_backend_service.frontend_service.id
}
# Cria um proxy HTTP de destino
resource "google_compute_target_http_proxy" "frontend_http_proxy" {
  name        = "frontend-http-proxy"
  url_map     = google_compute_url_map.frontend_http_url_map.id
  region      = var.region
}
# Cria a regra de encaminhamento global para o Load Balancer HTTP externo
resource "google_compute_global_forwarding_rule" "frontend_http_forwarding_rule" {
  name       = "frontend-http-forwarding-rule"
  ip_protocol = "TCP"
  port_range  = "80"
  target      = google_compute_target_http_proxy.frontend_http_proxy.id
  ip_address  = google_compute_address.frontend_lb_ip.address
}
# Criação do Internal Load Balancer para o Backend
# Reserva um endereço IP INTERNO para o Load Balancer
resource "google_compute_address" "backend_internal_lb_ip" {
  name         = "internal-lb-ip-backend"
  region       = var.region
  subnetwork   = google_compute_subnetwork.subnet_privada.id
  address_type = "INTERNAL"
  address      = "10.0.10.100" # Você pode especificar um IP dentro da subnet privada ou deixar o GCP atribuir um
}
# Cria um health check para o Load Balancer para o Frontend
resource "google_compute_health_check" "backend_http_health_check" {
  name        = "backend-http-health-check"
  http_health_check {
    port        = 80 # Porta em que sua aplicação backend responde
    request_path = "/internal" # Endpoint para verificar a saúde
  }
}
# Cria um REGIONAL service para o Load Balancer para o Backend
resource "google_compute_region_backend_service" "backend_service" {
  name                  = "backend-service"
  region                = var.region
  protocol              = "HTTP"
  health_checks         = [google_compute_health_check.backend_http_health_check.id]
  load_balancing_scheme = "INTERNAL_MANAGED"

  group {
    instance_group = google_compute_region_instance_group_manager.mig-app.instance_group
  }
}
# Cria a regra de encaminhamento regional para o Load Balancer HTTP interno
resource "google_compute_region_forwarding_rule" "backend_http_forwarding_rule_internal" {
  name         = "backend-http-forwarding-rule-internal"
  region       = var.region
  backend_service = google_compute_region_backend_service.backend_service.id
  ip_protocol  = "TCP"
  ports        = ["80"]
  load_balancing_scheme = "INTERNAL_MANAGED"
  ip_address   = google_compute_address.backend_internal_lb_ip.address
  subnetwork   = google_compute_subnetwork.subnet_privada.id
}
