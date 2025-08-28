# POS Flask

Sistema Punto de Venta web (Flask, SQLAlchemy, Bootstrap 5).

## Requisitos

- Python 3.11+
- pip

## Instalación local

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
flask db upgrade
python seed.py
flask run
```

## Docker

```bash
docker compose up --build -d
```

## Variables de entorno

- `DATABASE_URL`: URL de la base de datos. Por defecto SQLite (`sqlite:///instance/pos.db`). Para PostgreSQL: `postgresql://posuser:pospass@db:5432/posdb`
- `SECRET_KEY`: clave secreta Flask.
- `ADMIN_EMAIL`, `ADMIN_PASSWORD`: usuario admin inicial.

## Migraciones

```bash
flask db migrate
flask db upgrade
```

## Seed de datos demo

```bash
python seed.py
```

## Cambiar de SQLite a PostgreSQL

1. Cambia `DATABASE_URL` en `.env` a:  
   `postgresql://posuser:pospass@db:5432/posdb`
2. Ejecuta migraciones:  
   `flask db upgrade`
3. Reinicia la app.

## Comandos útiles

- `make dev` - Ejecuta servidor Flask.
- `make test` - Ejecuta pruebas.
- `make lint` - Linting con ruff.
- `make seed` - Pobla datos demo.
- `make docker` - Levanta Docker Compose.

## PDF de recibos

Se usa [WeasyPrint](https://weasyprint.org/) para generar PDFs desde HTML.

## Seguridad

- Contraseñas hasheadas con bcrypt.
- CSRF activo.
- Roles y permisos por blueprint.
- Validaciones robustas en formularios.

## Pruebas

Cobertura mínima 70%.  
Incluye tests de login, permisos, CRUD productos, ventas y stock.

---
