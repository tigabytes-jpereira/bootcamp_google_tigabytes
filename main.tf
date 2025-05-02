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
    "CREATE TABLE Tarefas (",
    "    id STRING(36) NOT NULL,",
    "    descricao STRING(MAX) NOT NULL,",
    "    concluida BOOL NOT NULL,",
    "    CONSTRAINT PK_Tarefas PRIMARY KEY (id)",
    ")"
  ]
}

# Criação da rede VPC
resource "google_compute_network" "vpc_network" {
  name                    = "app-network"
  auto_create_subnetworks = true
}

# Criação das regras de firewall
resource "google_compute_firewall" "frontend_firewall" {
  name    = "allow-frontend-http"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# Criação da regra de firewall para permitir tráfego HTTP (porta 8080 para backend)
resource "google_compute_firewall" "backend_firewall" {
  name    = "allow-backend-http"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# Criação da VM para o backend
resource "google_compute_instance" "backend_vm" {
  name         = var.backend_vm_name
  machine_type = var.backend_vm_machine_type
  zone         = var.backend_vm_zone
  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }
  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-pip
    pip3 install flask
    # Instale a biblioteca do cliente do Google Cloud Spanner
    pip3 install google-cloud-spanner

    # Crie o diretório para a aplicação
    mkdir -p /app
    cd /app
    wget https://github.com/tigabytes-jpereira/bootcamp_google_tigabytes/blob/main/app/app_backend.py
    wget https://github.com/tigabytes-jpereira/bootcamp_google_tigabytes/blob/main/app/requirements_backend.txt
    pip3 install -r requirements_backend.txt
    # Execute a aplicação backend
    export SPANNER_PROJECT="${var.project}"
    export SPANNER_INSTANCE="${google_spanner_instance.main.name}"
    export SPANNER_DATABASE="${google_spanner_database.tarefas.name}"
    python3 app_backend_spanner.py &
  EOF
  depends_on = [google_spanner_instance.main, google_spanner_database.tarefas, google_compute_firewall.backend_firewall]
}

# Criação da VM para o frontend (mantido)
resource "google_compute_instance" "frontend_vm" {
  name         = var.frontend_vm_name
  machine_type = var.frontend_vm_machine_type
  zone         = var.frontend_vm_zone
  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }
  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-pip
    pip3 install flask requests
    # Crie o diretório para a aplicação
    mkdir -p /app
    cd /app
    # Faça o upload do seu código frontend
    wget https://github.com/tigabytes-jpereira/bootcamp_google_tigabytes/blob/main/app/app_frontend.py
    wget https://github.com/tigabytes-jpereira/bootcamp_google_tigabytes/blob/main/app/index.html
    wget https://github.com/tigabytes-jpereira/bootcamp_google_tigabytes/blob/main/app/requirements_frontend.txt
    pip3 install -r requirements_frontend.txt
    export BACKEND_URL="http://${google_compute_instance.backend_vm.network_interface.0.access_config.0.nat_ip}:8080"
    python3 app_frontend.py &
  EOF
  depends_on = [google_compute_instance.backend_vm, google_compute_firewall.frontend_firewall]
}