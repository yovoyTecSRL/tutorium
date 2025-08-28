<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>{% block title %}POS System{% endblock %}</title>
	{% block head %}{% endblock %}
</head>
<body>
	<main>
		{% block content %}{% endblock %}
	</main>
	{% block scripts %}{% endblock %}
</body>
</html>
