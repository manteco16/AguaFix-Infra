# AguaFix — Entregables

## Datos del equipo

| Nombre | Matrícula |
|---|---|
| _(completar)_ | _(completar)_ |
| _(completar)_ | _(completar)_ |
| _(completar)_ | _(completar)_ |

## Enlaces

| Entregable | URL |
|---|---|
| Repositorio de la API | https://github.com/manteco16/AguaFix-API |
| Repositorio de infraestructura | https://github.com/manteco16/AguaFix-Infra |
| Repositorio del front | https://github.com/manteco16/AguaFix-Front |
| Imagen en Docker Hub | https://hub.docker.com/r/`<usuario-dockerhub>`/aguafix-api |
| API en producción | http://`<hostname-noip>`/ |
| Front en producción | http://`<hostname-noip>`/app/ |
| Video demostrativo | _(pegar URL del video)_ |

> Reemplaza los valores entre backticks después de ejecutar `terraform apply` y de publicar la imagen.

## Checklist de cumplimiento

| Requisito | Dónde se cumple | Evidencia |
|---|---|---|
| API NestJS + PostgreSQL + TypeORM | `AguaFix-API/src` | `npm run build`, `npm test` |
| Migraciones con `synchronize: false` | `src/db/data-source.ts`, `src/db/migrations` | Migraciones ejecutadas al arrancar el contenedor |
| Registro/login con bcrypt | `src/auth` | `POST /auth/register`, `POST /auth/login` |
| Subida de imágenes a S3 | `src/storage`, `src/reports` | Reporte con `photoUrl` en S3 |
| Correo con Nodemailer | `src/email` | Notificación al crear un reporte |
| `POST` y `GET` por entidad | `/auth`, `/user`, `/reports` | README de la API |
| Dockerfile `node:22-alpine` | `AguaFix-API/Dockerfile` | Imagen publicada en Docker Hub |
| `.dockerignore` sin secretos | `AguaFix-API/.dockerignore` | `.env`, `compose.yaml`, `node_modules`, `dist`, `.git` excluidos |
| Workflow build/push/deploy | `AguaFix-API/.github/workflows/docker-publish.yml` | Push a `main` → Docker Hub → SSH → `docker compose pull && up -d` |
| Terraform: SG 22/80/443 | `main.tf` | `terraform validate` |
| Terraform: key pair | `main.tf` | `aws_key_pair.api` |
| Terraform: EC2 + user_data | `main.tf`, `templates/user_data.sh.tpl` | Docker + PostgreSQL + API |
| Terraform: bucket S3 | `main.tf` | `aws_s3_bucket.images` |
| Terraform: No-IP | `templates/user_data.sh.tpl` | Cron cada 5 minutos |
| Variables y outputs | `variables.tf`, `outputs.tf`, `terraform.tfvars.example` | `terraform output` |
| API responde en `http://<hostname>/` | nginx → `127.0.0.1:3000` | `curl http://<hostname>/` |
| Front consume la API publicada | `AguaFix-Front/src/api.ts` | Rutas relativas, sin `localhost` |
| Front: registro/login | `src/components/AuthPanel.tsx` | Video |
| Front: crear reporte con imagen | `src/components/ReportForm.tsx` | Video |
| Front: listar entidades con imagen | `src/components/ReportList.tsx`, `UserList.tsx` | Video |
| Sin secretos en repos | `.gitignore` de los 3 repos | `git ls-files` no incluye `.env` ni `.tfvars` |

## Orden sugerido para la demostración

1. Repositorios y estructura.
2. Imagen en Docker Hub y workflow.
3. Terraform y recursos en AWS.
4. API en producción.
5. Front en producción.
6. Reporte con imagen.
7. Auto-despliegue.

El detalle está en [GUIA-VIDEO.md](GUIA-VIDEO.md).

## Notas de seguridad

- No se suben `.env`, `terraform.tfvars`, `.tfstate` ni llaves SSH.
- Las credenciales de AWS no están en el código: la EC2 usa un IAM instance profile.
- Las contraseñas de PostgreSQL, correo y No-IP se pasan como variables `sensitive` de Terraform y quedan en `/opt/aguafix/.env` con permisos `600`.
