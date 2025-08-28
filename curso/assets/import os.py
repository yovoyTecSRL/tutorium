import os
from flask import Flask, render_template
from dotenv import load_dotenv

load_dotenv()

def create_app():
    from pos.extensions import db, migrate, login_manager, csrf
    from pos.models import *  # Import models for Alembic
    from pos.blueprints.auth import bp as auth_bp
    from pos.blueprints.products import bp as products_bp
    from pos.blueprints.customers import bp as customers_bp
    from pos.blueprints.sales import bp as sales_bp
    from pos.blueprints.reports import bp as reports_bp
    from pos.blueprints.admin import bp as admin_bp

    app = Flask(__name__, instance_relative_config=True)
    env = os.environ.get("FLASK_ENV", "development")
    app.config.from_object(f"config.{env.capitalize()}Config")

    db.init_app(app)
    migrate.init_app(app, db)
    login_manager.init_app(app)
    csrf.init_app(app)

    app.register_blueprint(auth_bp)
    app.register_blueprint(products_bp, url_prefix="/products")
    app.register_blueprint(customers_bp, url_prefix="/customers")
    app.register_blueprint(sales_bp, url_prefix="/pos")
    app.register_blueprint(reports_bp, url_prefix="/reports")
    app.register_blueprint(admin_bp, url_prefix="/admin")

    @app.errorhandler(404)
    def not_found(e):
        return render_template("errors/404.html"), 404

    @app.errorhandler(500)
    def server_error(e):
        return render_template("errors/500.html"), 500

    return app

if __name__ == "__main__":
    app = create_app()
    app.run()
