<?php

declare(strict_types=1);

namespace App\Core;

use PDO;
use RuntimeException;

final class Database
{
    private PDO $pdo;

    public function __construct(array $config)
    {
        $host = (string) $config['host'];
        $port = (int) $config['port'];
        $database = (string) $config['database'];
        $charset = (string) $config['charset'];

        $dsn = sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=%s',
            $host,
            $port,
            $database,
            $charset
        );

        $sslMode = strtolower((string) ($config['ssl_mode'] ?? 'preferred'));
        $isLocalHost = $this->isLocalHost($host);
        $allowInsecureRemote = (bool) ($config['allow_insecure_remote'] ?? false);
        $sslCa = (string) ($config['ssl_ca'] ?? '');
        $verifyServerCert = (bool) ($config['ssl_verify_server_cert'] ?? true);

        if (!in_array($sslMode, ['disable', 'preferred', 'require', 'verify_ca', 'verify_identity'], true)) {
            throw new RuntimeException('APP_DB_SSL_MODE no soportado. Use disable, preferred, require, verify_ca o verify_identity.');
        }

        if (!$isLocalHost && !$allowInsecureRemote && in_array($sslMode, ['disable', 'preferred'], true)) {
            throw new RuntimeException('Conexión remota insegura bloqueada. Configure APP_DB_SSL_MODE=require o APP_DB_SSL_MODE=verify_ca/verify_identity.');
        }

        if (!$isLocalHost && !$allowInsecureRemote) {
            if (!$verifyServerCert) {
                throw new RuntimeException('Conexión remota insegura bloqueada. APP_DB_SSL_VERIFY_SERVER_CERT debe ser 1.');
            }

            if ($sslCa === '') {
                throw new RuntimeException('Conexión remota insegura bloqueada. Defina APP_DB_SSL_CA para validar el certificado del servidor.');
            }
        }

        $this->assertReadablePath('APP_DB_SSL_CA', (string) ($config['ssl_ca'] ?? ''));
        $this->assertReadablePath('APP_DB_SSL_CERT', (string) ($config['ssl_cert'] ?? ''));
        $this->assertReadablePath('APP_DB_SSL_KEY', (string) ($config['ssl_key'] ?? ''));

        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
            PDO::ATTR_TIMEOUT => 10,
        ];

        $this->applySslOptions($options, $config);

        $this->pdo = new PDO($dsn, $config['username'], $config['password'], $options);
    }

    public function pdo(): PDO
    {
        return $this->pdo;
    }

    private function isLocalHost(string $host): bool
    {
        return in_array(strtolower($host), ['localhost', '127.0.0.1', '::1', 'db_dev'], true);
    }

    private function applySslOptions(array &$options, array $config): void
    {
        $sslMode = strtolower((string) ($config['ssl_mode'] ?? 'preferred'));
        $sslCa = (string) ($config['ssl_ca'] ?? '');
        $sslCert = (string) ($config['ssl_cert'] ?? '');
        $sslKey = (string) ($config['ssl_key'] ?? '');
        $verifyServerCert = (bool) ($config['ssl_verify_server_cert'] ?? true);

        $tlsRequested = $sslMode !== 'disable' || $sslCa !== '' || $sslCert !== '' || $sslKey !== '';
        if (!$tlsRequested) {
            return;
        }

        if (defined('PDO::MYSQL_ATTR_SSL_CA') && $sslCa !== '') {
            $options[PDO::MYSQL_ATTR_SSL_CA] = $sslCa;
        }

        if (defined('PDO::MYSQL_ATTR_SSL_CERT') && $sslCert !== '') {
            $options[PDO::MYSQL_ATTR_SSL_CERT] = $sslCert;
        }

        if (defined('PDO::MYSQL_ATTR_SSL_KEY') && $sslKey !== '') {
            $options[PDO::MYSQL_ATTR_SSL_KEY] = $sslKey;
        }

        if (defined('PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT')) {
            $options[PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT] = $verifyServerCert;
        }
    }

    private function assertReadablePath(string $envName, string $path): void
    {
        if ($path === '') {
            return;
        }

        if (!is_readable($path)) {
            throw new RuntimeException($envName . ' apunta a un archivo no legible dentro del contenedor.');
        }
    }
}
