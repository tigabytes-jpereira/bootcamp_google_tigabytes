variable "project" {
  description = "Projeto GCP a ser utilizado para o Lab"
  default     = "PROJECT_NAME"  #Deve ser alterado de acordo com seu ambiente
}

variable "region" {
  description = "Região a ser utilizado para o Lab"
  type        = string
  default     = "southamerica-east1"
}

variable "zone1" {
  description = "Zona dentro da Região a ser utilizado para o Lab"
  type        = string
  default     = "southamerica-east1-a"
}

variable "zone2" {
  description = "Zona dentro da Região a ser utilizado para o Lab"
  type        = string
  default     = "southamerica-east1-b"
}

variable "zone3" {
  description = "Zona dentro da Região a ser utilizado para o Lab"
  type        = string
  default     = "southamerica-east1-c"
}

variable "spanner_instance_name" {
  type        = string
  default     = "scclab-spanner"
  description = "Nome da instância do Cloud Spanner"
}

variable "spanner_config" {
  type        = string
  default     = "regional-southamerica-east1"
  description = "Configuração da instância do Cloud Spanner"
}

variable "spanner_database_name" {
  type        = string
  default     = "tarefas_db"
  description = "Nome do banco de dados do Spanner"
}

variable "bucket_name" {
  description = "Nome único para o bucket a ser criado."
  default     = "bucket-scclab-PROJECT_NAME" #Deve ser alterado com um nome único global
}

variable "target_size" {
  description = "The target number of running instances for this managed instance group. This value should always be explicitly set unless this resource is attached to an autoscaler, in which case it should never be set."
  default     = 3
}
