# AguaFix Infraestructura

Infraestructura completa en AWS creada con Terraform para publicar AguaFix en producción.

## Arquitectura

```
Internet
   │
   ▼
No-IP (aguafix-equipo1.ddns.net)
   │
   ▼
EC2 Ubuntu 24.04 + IP elástica
   ├── nginx :80
   │     ├── /       → API NestJS (contenedor :3000)
   │     └── /app/   → front estático (React + Vite)
   ├── Docker Compose
   │     ├── aguafix-api (imagen de Docker Hub)
   │     └── aguafix-db  (PostgreSQL 16)
   ├── IAM instance profile → PutObject en S3
   └── cron → actualiza No-IP cada 5 minutos
```

Terraform crea:

- Security group con puertos 22, 80 y 443.
- Key pair y llave SSH.
- Instancia EC2 Ubuntu 24.04 con IP elástica.
- IAM role + instance profile para subir imágenes a S3 sin claves en el `.env`.
- Bucket S3 para imágenes (lectura pública de objetos).
- `user_data` que instala Docker, nginx, escribe el compose, levanta API + PostgreSQL y actualiza No-IP.

## Requisitos previos

1. Terraform >= 1.6.
2. AWS CLI configurado (`aws configure`) con permisos para EC2, S3, IAM y EIP.
3. Una llave SSH local.
4. Un hostname creado en [No-IP](https://www.noip.com/).
5. La imagen de la API publicada en Docker Hub (ejecutar el workflow de la API al menos una vez).

## 1. Crear el hostname en No-IP

Entra a No-IP → **Dynamic DNS** → **Create Hostname**.

Ejemplo:

- Hostname: `aguafix-equipo1`
- Domain: `ddns.net`
- IP: cualquiera (Terraform la actualizará)

Guarda el usuario, la contraseña y el hostname para `terraform.tfvars`.

## 2. Crear la llave SSH

```bash
ssh-keygen -t ed25519 -f ~/.ssh/aguafix -C "aguafix"
```

Se generan:

- `~/.ssh/aguafix` (privada, va en el secreto `EC2_SSH_KEY`)
- `~/.ssh/aguafix.pub` (pública, la usa Terraform)

## 3. Publicar la imagen de la API

Antes del primer `terraform apply`, la imagen debe existir en Docker Hub:

```bash
docker build -t <usuario>/aguafix-api:latest .
docker push <usuario>/aguafix-api:latest
```

O ejecuta el workflow de GitHub Actions del repo de la API.

## 4. Configurar variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Completa `terraform.tfvars` con tus datos reales. **No lo subas al repositorio.**

## 5. Crear la infraestructura

```bash
terraform init
terraform plan
terraform apply
```

Al terminar, Terraform muestra:

- `public_ip`
- `api_url` → `http://<hostname-noip>/`
- `front_url` → `http://<hostname-noip>/app/`
- `ssh_command`
- `s3_bucket`
- `docker_image`

Espera uno o dos minutos a que el `user_data` termine y No-IP actualice el DNS.

Comprueba:

```bash
curl http://<hostname-noip>/
curl http://<hostname-noip>/health
```

## 6. Configurar GitHub Secrets

En el repo de la **API**:

| Secreto | Valor |
|---|---|
| `DOCKER_USER` | Usuario de Docker Hub |
| `DOCKER_PASSWORD` | Token/contraseña de Docker Hub |
| `EC2_HOST` | Hostname de No-IP (o IP elástica) |
| `EC2_SSH_KEY` | Contenido completo de `~/.ssh/aguafix` |

En el repo del **front**:

| Secreto | Valor |
|---|---|
| `EC2_HOST` | Hostname de No-IP (o IP elástica) |
| `EC2_SSH_KEY` | Contenido completo de `~/.ssh/aguafix` |

El usuario SSH es siempre `ubuntu`.

## 7. Desplegar

- Push a `main` en la API → build/push a Docker Hub → SSH → `docker compose pull && docker compose up -d`.
- Push a `main` en el front → build de Vite → `scp` a `/var/www/aguafix/app`.

El front queda en `http://<hostname-noip>/app/` y consume la API en el mismo dominio mediante rutas relativas.

## 8. Destruir

```bash
terraform destroy
```

El bucket tiene `force_destroy = true`, así que se elimina junto con las imágenes. El hostname de No-IP se queda creado (se puede borrar manualmente en noip.com).

## Seguridad

- `terraform.tfvars`, `terraform.tfstate`, llaves SSH y `.env` están en `.gitignore`.
- Las credenciales de AWS no se escriben en ningún archivo: la EC2 usa un IAM instance profile.
- Las contraseñas de PostgreSQL, correo y No-IP se pasan como variables `sensitive`.
- El puerto 5432 no se expone a internet.
- La API escucha en `127.0.0.1:3000` y solo nginx la publica por el puerto 80.

## Notas

- No-IP gratuito puede pedir confirmación periódica del hostname.
- Si tu cuenta de AWS tiene “Block all public access” a nivel de cuenta, la lectura pública de imágenes puede fallar. Desactívalo a nivel de cuenta o usa URLs prefirmadas.
- Para HTTPS, el siguiente paso sería agregar Certbot o Caddy sobre nginx.
