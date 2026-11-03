<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= htmlspecialchars($title ?? 'Finanzas Personales', ENT_QUOTES, 'UTF-8') ?></title>
</head>
<body>
  <h1><?= htmlspecialchars($title ?? 'Finanzas Personales', ENT_QUOTES, 'UTF-8') ?></h1>
  <p>Entorno MVC inicial listo.</p>
  <ul>
    <li>Ruta principal: <a href="/">/</a></li>
    <li>Salud del servicio: <a href="/health">/health</a></li>
  </ul>
</body>
</html>
