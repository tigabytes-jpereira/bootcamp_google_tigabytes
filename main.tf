# Criação da instância do Cloud Spanner
resource "google_spanner_instance" "main" {
  name         = var.spanner_instance_name
  project      = var.project
  config       = var.spanner_config
  display_name = var.spanner_instance_name
  num_nodes    = 1 # Comece com 1 nó para demonstração, aumente conforme necessário
  force_destroy = true
}
# Criação do banco de dados do Spanner
resource "google_spanner_database" "tarefas" {
  name     = var.spanner_database_name
  project         = var.project
  instance = google_spanner_instance.main.name
  ddl = [
    "CREATE TABLE Tarefas (id STRING(36) NOT NULL PRIMARY KEY, descricao STRING(MAX) NOT NULL, concluida BOOL NOT NULL)"
  ]
  deletion_protection = false
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
  force_destroy = true
}
#Realizando o upload de um arquivo
resource "google_storage_bucket_object" "backend" {
 name         = "scclab-script-backend.sh"
 bucket       = google_storage_bucket.scclab-bkt.id
 source       = "./scclab-script-backend.sh"
}
resource "google_storage_bucket_object" "frontend" {
 name         = "scclab-script-frontend.sh"
 bucket       = google_storage_bucket.scclab-bkt.id
 source       = "./scclab-script-frontend.sh"
}
#Criando instância Memorystore for Redis
module "memorystore" {
   source  = "terraform-google-modules/memorystore/google"
   version = "~> 14.0"

   name           = "memorystore"
   tier           = "STANDARD_HA"
   project_id     = var.project
   memory_size_gb = 5
   enable_apis    = "true"
   region         = var.region
   replica_count  = 2
   read_replicas_mode  = "READ_REPLICAS_ENABLED"
 }
# Criação da rede VPC
resource "google_compute_network" "vpc_network" {
  auto_create_subnetworks = false
  name                    = "scclab-network"
  project      = var.project
  }
# Criação da subnet Publica
resource "google_compute_subnetwork" "subnet_publica" {
  ip_cidr_range = "10.0.20.0/24"
  name          = "scclab-pubsn-frontend"
  network       = google_compute_network.vpc_network.id
  region        = var.region
  project       = var.project
}
# Criação da subnet Privada
resource "google_compute_subnetwork" "subnet_privada" {
  ip_cidr_range = "10.0.10.0/24"
  name          = "scclab-pvtsn-app"
  network       = google_compute_network.vpc_network.id
  region        = var.region
  project       = var.project
  private_ip_google_access = true
}
#Criando a Subnet Proxy-only para o Internal LB
resource "google_compute_subnetwork" "proxy_only_subnet" {
  name                     = "proxy-only-subnet"
  purpose                  = "REGIONAL_MANAGED_PROXY"
  role                     = "ACTIVE"
  ip_cidr_range            = "10.129.0.0/23" # Intervalo de IP dedicado para a sub-rede proxy-only
  network                  = google_compute_network.vpc_network.id
  region                   = var.region
  project                  = var.project
}
# Cria um endereço IP público para o NAT gateway
resource "google_compute_address" "nat_ip" {
  name   = "nat-ip-backend"
  region = var.region
  project         = var.project
}
# Cria o Cloud NAT gateway para permitir que instâncias na subnet privada acessem a internet
resource "google_compute_router" "router_nat" {
  name    = "router-nat-backend"
  network = google_compute_network.vpc_network.id
  region  = var.region
  project         = var.project
}
resource "google_compute_router_nat" "nat_config" {
  name                               = "nat-config-backend"
  project                            = var.project
  router                             = google_compute_router.router_nat.name
  region                             = google_compute_router.router_nat.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_ip.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
# Regra de firewall para permitir tráfego HTTP e HTTPS de qualquer lugar para a subnet pública
resource "google_compute_firewall" "allow_http_https_frontend" {
  name    = "scclab-allow-http-https-frontend"
  project = var.project
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
  project = var.project
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
  project = var.project
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
  project = var.project
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
  project = var.project
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "icmp"
  }
  direction     = "INGRESS"
  target_tags   = ["app-server"]
  source_ranges = ["0.0.0.0/0"] #Comentar para corrigir erros apontados pelo SCC
#  source_ranges = ["10.0.20.0/24"] #Permitir apenas a partir da subnet publica #Remover comentário para corrigir erros apontados pelo SCC
}
# Regra de firewall para permitir o health check do load balancer nas instâncias do frontend e backend
resource "google_compute_firewall" "allow_health_check" {
  name    = "scclab-allow-health-check"
  project = var.project
  network = google_compute_network.vpc_network.name
  allow {
    ports    = ["80", "443"] # Assumindo que sua aplicação backend responde na porta 80
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
    startup-script  = "#!/bin/bash\nsudo wget https://github.com/tigabytes-jpereira/bootcamp_google_tigabytes/raw/refs/heads/main/scclab-script-frontend.sh\nsudo chmod +x scclab-script-frontend.sh\nsudo ./scclab-script-frontend.sh"
  }
  
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  depends_on = [google_compute_network.vpc_network, google_compute_subnetwork.subnet_publica]
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
    startup-script  = "#!/bin/bash\nsudo wget https://github.com/tigabytes-jpereira/bootcamp_google_tigabytes/raw/refs/heads/main/scclab-script-backend.sh\nsudo chmod +x scclab-script-backend.sh\nsudo ./scclab-script-backend.sh"
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  depends_on = [google_compute_network.vpc_network, google_compute_subnetwork.subnet_privada]
}
# Criação do MIG (Managed Instance Group) de Frontend
resource "google_compute_region_instance_group_manager" "mig-web" {
  name                      = "mig-web"
  project                   = var.project
  region                    = var.region
  distribution_policy_zones = [var.zone1, var.zone2, var.zone3] #Considerando a região de US-EAST1, preencha de acordo com a região escolhida
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
  project                   = var.project
  region                    = var.region
  distribution_policy_zones = [var.zone1, var.zone2, var.zone3] #Considerando a região de US-EAST1, preencha de acordo com a região escolhida
  target_size               = var.target_size
  base_instance_name        = "instance-template-app"
  version {
    instance_template = google_compute_instance_template.instance-template-app.self_link
  }
  depends_on = [google_compute_instance_template.instance-template-app]
}
#Criando a Security Policy a ser aplicada ao Cloud Armor
resource "google_compute_security_policy" "cloud_armor_enterprise_policy" {
  name        = "armor-policy-frontend-lb"
  project     = var.project                  
  description = "Política de segurança Enterprise para o Load Balancer"
  type        = "CLOUD_ARMOR"

  rule {
    priority    = 100
    action      = "allow"
    description = "Permite apenas conexões oriundas do Brasil"
    match {
      expr {
        expression = "inIpRange(origin.ip, 'origin.region_code == 'BR'')"
      }
    }
  }
  rule {
    priority    = 1001
    action      = "deny(403)"
    description = "Bloquear IPs oriundos da China"
    match {
      expr {
        expression = "inIpRange(origin.ip, 'origin.region_code == 'CN'')"
      }
    }
  }
  rule {
    priority    = 1002
    action      = "deny(403)"
    description = "Cross-Site Scripting"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('xss-v33-stable')"
      }
    }
  }
  rule {
    priority    = 1003
    action      = "deny(403)"
    description = "SQL Injection"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sqli-v33-stable')"
      }
    }
  }
  rule {
    priority    = 1004
    action      = "deny(403)"
    description = "Local File Inclusion (LFI)"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('lfi-v33-stable')"
      }
    }
  }
  rule {
    priority    = 1005
    action      = "deny(403)"
    description = "Remote Code Execution (RCE)"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('rce-v33-stable')"
      }
    }
  }
  rule {
    priority    = 1006
    action      = "deny(403)"
    description = "Scanner Detection"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('scannerdetection-v33-stable')"
      }
    }
  }
  rule {
    priority    = 1007
    action      = "deny(403)"
    description = "Protocol attack"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('protocolattack-v33-stable')"
      }
    }
  }
  rule {
    priority    = 1008
    action      = "deny(403)"
    description = "PHP Injection Attack"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('php-v33-stable')"
      }
    }
  }
  rule {
    priority    = 1009
    action      = "deny(403)"
    description = "Session Fixation"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sessionfixation-v33-stable')"
      }
    }
  }
  rule {
    priority    = 1010
    action      = "deny(403)"
    description = "Java Attack"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('java-v33-stable')"
      }
    }
  }
  rule {
    priority    = 1011
    action      = "deny(403)"
    description = "NodeJS Attack"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('nodejs-v33-stable')"
      }
    }
  }
  rule {
    priority    = 1012
    action      = "deny(403)"
    description = "CVE and other vulnerabilities"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('cve-canary')"
      }
    }
  }
  rule {
    priority    = 2147483647
    action      = "deny(403)"
    description = "Default rule, higher priority overrides its"
    match {
      config {
        src_ip_ranges = ["*"]
      }
    }
  }                     
}
# Reserva de IP Público e criação do External Load Balancer para o Frontend
resource "google_compute_address" "frontend_lb_ip" {
  name   = "scclab-lb-frontend-ip"
  region = var.region
  address_type = "EXTERNAL"
  project = var.project
}
module "external_lb" {
  source = "GoogleCloudPlatform/lb-http/google"
  version = "~> 12.0" # Use a versão mais recente ou a desejada

  name            = "scclab-external-lb"
  project         = var.project
  
  backends = {
    default = {
      port                        = "80"
      protocol                    = "HTTP"
      timeout_sec                 = 10
      enable_cdn                  = false
      security_policy             = google_compute_security_policy.cloud_armor_enterprise_policy.id
      health_check = {
        request_path        = "/"
        port                = "80"
        protocol            = "HTTP"
        check_interval_sec  = 10
        timeout_sec         = 5
        healthy_threshold   = 2
        unhealthy_threshold = 5
      }

      log_config = ({
        enable      = false
      })

      groups = [
        {
          group = google_compute_region_instance_group_manager.mig-web.instance_group
        },
      ]
    }
  }
  address    = google_compute_address.frontend_lb_ip.address
  depends_on = [google_compute_network.vpc_network, google_compute_subnetwork.subnet_publica, google_compute_region_instance_group_manager.mig-web, google_compute_security_policy.cloud_armor_enterprise_policy]
}
# Reserva de IP Privado e criação do Internal Load Balancer para o Backend
resource "google_compute_address" "backend_internal_lb_ip" {
  name         = "internal-lb-ip-backend"
  project      = var.project
  region       = var.region
  subnetwork   = google_compute_subnetwork.subnet_privada.id
  address_type = "INTERNAL"
  address      = "10.0.10.100" # Você pode especificar um IP dentro da subnet privada ou deixar o GCP atribuir um
  depends_on     = [google_compute_subnetwork.subnet_privada]
}
# Cria um health check para o Load Balancer para o Frontend
resource "google_compute_region_health_check" "backend_http_health_check" {
  name        = "backend-http-health-check"
  provider    = google-beta
  project     = var.project
  region      = var.region
  http_health_check {
    port        = 80 # Porta em que sua aplicação backend responde
  }
}
# Cria um REGIONAL service para o Load Balancer para o Backend
resource "google_compute_region_backend_service" "backend_service" {
  name                  = "backend-service"
  project               = var.project
  provider              = google-beta
  region                = var.region
  protocol              = "HTTP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  timeout_sec           = 10
  health_checks         = [google_compute_region_health_check.backend_http_health_check.id]
      
   backend {
    group = google_compute_region_instance_group_manager.mig-app.instance_group
    balancing_mode        = "UTILIZATION"
    capacity_scaler = 1.0
  }
  depends_on     = [google_compute_region_health_check.backend_http_health_check, google_compute_region_instance_group_manager.mig-app]
}
# URL map
resource "google_compute_region_url_map" "backend_http_url_map" {
  name            = "backend-http-url-map"
  project               = var.project
  provider        = google-beta
  region          = var.region
  default_service = google_compute_region_backend_service.backend_service.id
  depends_on     = [google_compute_region_backend_service.backend_service]
}
# HTTP target proxy
resource "google_compute_region_target_http_proxy" "backend_target_http_proxy" {
  name     = "backend-target-http-proxy"
  project               = var.project
  provider = google-beta
  region   = var.region
  url_map  = google_compute_region_url_map.backend_http_url_map.id
  depends_on     = [google_compute_region_url_map.backend_http_url_map]
}
# Cria a regra de encaminhamento regional para o Load Balancer HTTP interno
resource "google_compute_forwarding_rule" "backend_http_forwarding_rule_internal" {
  name         = "backend-http-forwarding-rule-internal"
  project               = var.project
  provider     = google-beta
  region       = var.region
  depends_on     = [google_compute_subnetwork.proxy_only_subnet, google_compute_region_target_http_proxy.backend_target_http_proxy]
  ip_protocol  = "TCP"
  port_range   = "80"
  load_balancing_scheme = "INTERNAL_MANAGED"
  target       = google_compute_region_target_http_proxy.backend_target_http_proxy.id
  ip_address   = google_compute_address.backend_internal_lb_ip.address
  subnetwork   = google_compute_subnetwork.subnet_privada.id
  allow_global_access   = false
  network_tier          = "PREMIUM"
}
