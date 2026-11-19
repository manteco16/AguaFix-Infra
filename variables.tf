variable "aws_region" {
  description = "Región de AWS donde se crea la infraestructura."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto, usado para nombrar recursos."
  type        = string
  default     = "aguafix"
}

variable "environment" {
  description = "Ambiente (prod, dev, etc.)."
  type        = string
  default     = "prod"
}

variable "instance_type" {
  description = "Tipo de instancia EC2."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nombre del key pair en AWS."
  type        = string
  default     = "aguafix-key"
}

variable "public_key_path" {
  description = "Ruta local de la llave pública SSH (.pub)."
  type        = string
  default     = "~/.ssh/aguafix.pub"
}

variable "ssh_private_key_path" {
  description = "Ruta local de la llave privada. Solo se usa para el output ssh_command."
  type        = string
  default     = "~/.ssh/aguafix"
}

variable "ssh_allowed_cidr" {
  description = "CIDR permitido para SSH. GitHub Actions requiere 0.0.0.0/0."
  type        = string
  default     = "0.0.0.0/0"
}

variable "docker_user" {
  description = "Usuario de Docker Hub donde se publica la API."
  type        = string
}

variable "api_image" {
  description = "Imagen completa de la API. Si está vacía se usa <docker_user>/aguafix-api:latest."
  type        = string
  default     = ""
}

variable "bucket_name" {
  description = "Nombre del bucket S3. Si está vacío se genera uno único con el account ID."
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Tamaño en GB del disco de la EC2."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Nombre de la base de datos PostgreSQL."
  type        = string
  default     = "aguafix"
}

variable "db_user" {
  description = "Usuario de PostgreSQL."
  type        = string
  default     = "aguafix"
}

variable "db_password" {
  description = "Contraseña de PostgreSQL."
  type        = string
  sensitive   = true
}

variable "mailer_service" {
  description = "Servicio de correo para nodemailer (gmail, outlook, etc.)."
  type        = string
  default     = "gmail"
}

variable "mailer_user" {
  description = "Cuenta de correo que envía los mensajes."
  type        = string
}

variable "mailer_password" {
  description = "Contraseña de aplicación del correo."
  type        = string
  sensitive   = true
}

variable "mailer_to" {
  description = "Correo destino de las notificaciones."
  type        = string
}

variable "mapbox_token" {
  description = "Token de Mapbox (opcional)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "noip_username" {
  description = "Usuario de No-IP."
  type        = string
  sensitive   = true
}

variable "noip_password" {
  description = "Contraseña de No-IP."
  type        = string
  sensitive   = true
}

variable "noip_hostname" {
  description = "Hostname creado en No-IP, por ejemplo aguafix-equipo1.ddns.net."
  type        = string
}

variable "cors_origins" {
  description = "Orígenes permitidos por CORS, separados por coma. Vacío = todos."
  type        = string
  default     = ""
}
