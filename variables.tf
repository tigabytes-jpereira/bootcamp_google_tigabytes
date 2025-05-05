variable "project" {
  description = "Projeto GCP a ser utilizado para o Lab"
  default     = "MUDE_O_NOME_DO_PROJETO"
}

variable "region" {
  description = "Região a ser utilizado para o Lab"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "Zona dentro da Região a ser utilizado para o Lab"
  type        = string
  default     = "us-east1-b"
}

variable "spanner_instance_name" {
  type        = string
  default     = "scclab-spanner"
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

variable "bucket_name" {
  description = "Nome único para o bucket a ser criado."
  default     = "INSIRA_UM_NOME_UNICO"
}

variable "target_size" {
  description = "The target number of running instances for this managed instance group. This value should always be explicitly set unless this resource is attached to an autoscaler, in which case it should never be set."
  default     = 3
}
