variable "spanner_instance_name" {
  type        = string
  default     = "app-tres-camadas-spanner"
  description = "Nome da instância do Cloud Spanner"
}

variable "spanner_config" {
  type        = string
  default     = "regional-us-east1" # Configuração regional em Carolina do Sul
  description = "Configuração da instância do Cloud Spanner"
}

variable "spanner_database_name" {
  type        = string
  default     = "tarefas_db"
  description = "Nome do banco de dados do Spanner"
}

/* variable "cloudsql_user" {
  type        = string
  default     = "app_user"
  description = "Nome do usuário do banco de dados"
}

variable "cloudsql_password" {
  type        = string
  sensitive   = true
  description = "Senha do usuário do banco de dados"
} */

variable "backend_vm_name" {
  type        = string
  default     = "backend-vm"
  description = "Nome da VM para o backend"
}

variable "backend_vm_machine_type" {
  type        = string
  default     = "e2-micro"
  description = "Tipo de máquina para a VM do backend"
}

variable "backend_vm_zone" {
  type        = string
  default     = "us-east1-b"
  description = "Zona da VM do backend"
}

variable "frontend_vm_name" {
  type        = string
  default     = "frontend-vm"
  description = "Nome da VM para o frontend"
}

variable "frontend_vm_machine_type" {
  type        = string
  default     = "e2-micro"
  description = "Tipo de máquina para a VM do frontend"
}

variable "frontend_vm_zone" {
  type        = string
  default     = "us-east1-b" # Usando uma zona diferente para alta disponibilidade (opcional)
  description = "Zona da VM do frontend"
}

variable "vm_image" {
  type        = string
  default     = "debian-cloud/debian-11" # Imagem base para as VMs
  description = "Imagem do sistema operacional para as VMs"
}