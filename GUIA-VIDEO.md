# Guion del video (orden a–g)

> Duración sugerida: 8–12 minutos. Ten a la mano las URLs, pero **nunca muestres** `.env`, `terraform.tfvars`, `.tfstate` ni llaves SSH.

## a) Repositorio de la API

Muestra en GitHub `manteco16/AguaFix-API`:

- `README.md` con endpoints y variables de entorno.
- `src/main.ts` (CORS, puerto, `0.0.0.0`).
- `src/db/data-source.ts` y `src/db/migrations` (migraciones, `synchronize: false`).
- `src/auth` (registro/login con bcrypt), `src/storage` (S3) y `src/email` (Nodemailer).

Comando de apoyo:

```bash
npm run build
npm test -- --runInBand
```

## b) Dockerfile, Docker Hub y GitHub Actions

- Abre `Dockerfile` y explica las 3 etapas (`deps`, `build`, `runner`) y `CMD ["node", "dist/main"]`.
- Abre `.dockerignore` y señala que excluye `.env`, `compose.yaml`, `node_modules`, `dist` y `.git`.
- Entra a Docker Hub y muestra la imagen `<usuario>/aguafix-api:latest` con sus tags.
- Abre `.github/workflows/docker-publish.yml` y explica:
  1. Login a Docker Hub con secretos.
  2. Build y push de `latest` y del SHA.
  3. SSH a la EC2 y `docker compose pull && docker compose up -d`.

## c) Infraestructura con Terraform

En el repo `manteco16/AguaFix-Infra`:

- `main.tf`: security group (22/80/443), key pair, EC2, IAM instance profile, bucket S3, IP elástica y `user_data`.
- `templates/user_data.sh.tpl`: instala Docker, nginx, escribe `/opt/aguafix/.env`, levanta PostgreSQL + API y configura No-IP con cron.
- `variables.tf`, `outputs.tf` y `terraform.tfvars.example`.

Muestra la salida real (sin enseñar el `.tfvars`):

```bash
terraform output
terraform state list
```

En la consola de AWS, muestra la instancia EC2, el security group y el bucket S3 creados por Terraform (no crees nada a mano).

## d) API en producción

```bash
curl http://<hostname-noip>/
curl http://<hostname-noip>/health
```

Muestra en el navegador `http://<hostname-noip>/` y explica que nginx hace proxy al contenedor de la API en `127.0.0.1:3000`.

## e) Front en producción

Abre `http://<hostname-noip>/app/`.

- Regístrate con un usuario nuevo.
- Cierra sesión e inicia sesión con ese usuario.
- Señala que el front consume la API con rutas relativas (`/auth`, `/reports`, `/user`), sin `localhost`.

## f) Reporte con imagen

- Ve a **Nuevo reporte**.
- Llena dirección, descripción, severidad y teléfono.
- Adjunta una foto y envía.
- Muestra el mensaje de éxito, el correo de notificación (si está configurado) y el reporte en la lista con la imagen cargada desde S3.
- Abre la pestaña **Usuarios** para mostrar el listado de entidades.

## g) Auto-despliegue y cierre

1. Haz un cambio pequeño en el front o en la API y súbelo a `main`.
2. Abre GitHub Actions y muestra el workflow en ejecución.
3. En la API, muestra el job de deploy conectándose por SSH a la EC2.
4. En la EC2 (o en los logs del workflow), muestra:

```bash
cd /opt/aguafix
sudo docker compose ps
sudo docker compose logs --tail=50 api
```

5. Cierra con la arquitectura:

```
No-IP → EC2 (nginx :80)
          ├── /      → API NestJS (:3000)
          └── /app/  → front React
EC2 → S3 (imágenes) + PostgreSQL 16 (contenedor)
GitHub Actions → Docker Hub → SSH → docker compose pull/up
```

## Puntos a mencionar

- `synchronize: false` y migraciones ejecutadas al arrancar el contenedor.
- Credenciales fuera del código: secretos de GitHub, variables `sensitive` de Terraform e IAM instance profile.
- El puerto 5432 no está expuesto a internet.
- No-IP se actualiza cada 5 minutos con IMDSv2.
- `terraform destroy` elimina la infraestructura (el bucket tiene `force_destroy = true`).
