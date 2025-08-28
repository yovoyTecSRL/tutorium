from flask import render_template, redirect, url_for, flash, request
from flask_login import login_user, logout_user, login_required
from pos.models.user import User
from pos.extensions import db, login_manager
from . import bp
from pos.forms.login_form import LoginForm
from passlib.hash import bcrypt

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

@bp.route("/auth/login", methods=["GET", "POST"])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(email=form.email.data).first()
        if user and bcrypt.verify(form.password.data, user.password_hash):
            login_user(user)
            return redirect(url_for("sales.pos"))
        flash("Credenciales inválidas", "danger")
    return render_template("auth/login.html", form=form)

@bp.route("/auth/logout")
@login_required
def logout():
    logout_user()
    return redirect(url_for("auth.login"))
