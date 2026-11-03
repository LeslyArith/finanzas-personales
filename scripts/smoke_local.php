<?php

declare(strict_types=1);

putenv('APP_DB_HOST=db_dev');
putenv('APP_DB_PORT=3306');
putenv('APP_DB_NAME=finanzas_personales_dev');
putenv('APP_DB_USER=finanzas_dev');
putenv('APP_DB_PASSWORD=finanzas_dev_pass');
putenv('APP_DB_SSL_MODE=preferred');
putenv('APP_DB_ALLOW_INSECURE_REMOTE=1');

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

$space = new App\Models\SpaceModel();
$id = $space->create([
    'tipo' => 'GRUPO',
    'nombre' => 'Demo local ' . date('His'),
    'moneda_referencia' => 'MXN',
    'zona_horaria' => 'America/Ciudad_Juarez',
    'fecha_inicio' => date('Y-m-d'),
    'activo' => 1,
]);

$rows = $space->list(3);

echo 'LOCAL_WRITE_SPACE=OK' . PHP_EOL;
echo 'LOCAL_SPACE_ID=' . $id . PHP_EOL;
echo 'LOCAL_READ_SPACES=' . count($rows) . PHP_EOL;
