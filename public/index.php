<?php

declare(strict_types=1);

spl_autoload_register(static function (string $class): void {
    $prefix = 'App\\';
    $baseDir = __DIR__ . '/../app/';

    if (strncmp($prefix, $class, strlen($prefix)) !== 0) {
        return;
    }

    $relativeClass = substr($class, strlen($prefix));
    $file = $baseDir . str_replace('\\', '/', $relativeClass) . '.php';

    if (is_file($file)) {
        require $file;
    }
});

$config = require __DIR__ . '/../config/app.php';
if (!empty($config['timezone'])) {
    date_default_timezone_set($config['timezone']);
}

$router = new App\Core\Router();
$routes = require __DIR__ . '/../config/routes.php';

foreach ($routes as [$method, $path, $handler]) {
    $router->add($method, $path, $handler);
}

$requestPath = (string) parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);

if ($requestPath === '/index.php') {
    $requestPath = '/';
} elseif (str_starts_with($requestPath, '/index.php/')) {
    $requestPath = substr($requestPath, strlen('/index.php'));
}

if (isset($_GET['route']) && is_string($_GET['route']) && $_GET['route'] !== '') {
    $requestPath = $_GET['route'];
}

$router->dispatch($_SERVER['REQUEST_METHOD'] ?? 'GET', $requestPath);
