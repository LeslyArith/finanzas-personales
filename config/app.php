<?php

declare(strict_types=1);

return [
    'name' => getenv('APP_NAME') ?: 'Finanzas Personales',
    'timezone' => 'America/Ciudad_Juarez',
    'db' => [
        'host' => getenv('APP_DB_HOST') ?: 'db_dev',
        'port' => (int) (getenv('APP_DB_PORT') ?: 3306),
        'database' => getenv('APP_DB_NAME') ?: 'finanzas_personales_dev',
        'username' => getenv('APP_DB_USER') ?: 'finanzas_dev',
        'password' => getenv('APP_DB_PASSWORD') ?: 'finanzas_dev_pass',
        'charset' => 'utf8mb4',
        'ssl_mode' => strtolower((string) (getenv('APP_DB_SSL_MODE') ?: 'preferred')),
        'ssl_ca' => getenv('APP_DB_SSL_CA') ?: null,
        'ssl_cert' => getenv('APP_DB_SSL_CERT') ?: null,
        'ssl_key' => getenv('APP_DB_SSL_KEY') ?: null,
        'ssl_verify_server_cert' => (getenv('APP_DB_SSL_VERIFY_SERVER_CERT') ?: '1') !== '0',
        'allow_insecure_remote' => (getenv('APP_DB_ALLOW_INSECURE_REMOTE') ?: '0') === '1',
    ],
];
