venv:
	python -m venv .venv

dev:
	FLASK_APP=app.py FLASK_ENV=development flask run

lint:
	ruff pos

test:
	pytest --cov=pos tests/

seed:
	python seed.py

migrate:
	flask db migrate

upgrade:
	flask db upgrade

docker:
	docker compose up --build -d
