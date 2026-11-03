<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database;

final class HealthModel
{
    public function databaseOk(): bool
    {
        $config = require __DIR__ . '/../../config/app.php';
        $db = new Database($config['db']);
        $stmt = $db->pdo()->query('SELECT 1 AS ok');
        $row = $stmt->fetch();

        return (int) ($row['ok'] ?? 0) === 1;
    }
}
