<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database;

final class SpaceModel
{
    public function list(int $limit): array
    {
        $db = $this->database();
        $sql = 'SELECT id, tipo, propietario_personal_id, nombre, moneda_referencia, zona_horaria, fecha_inicio, activo
                FROM espacios
                ORDER BY id DESC
                LIMIT :limit';

        $stmt = $db->pdo()->prepare($sql);
        $stmt->bindValue(':limit', $limit, \PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    public function create(array $payload): int
    {
        $db = $this->database();

        $sql = 'INSERT INTO espacios (tipo, propietario_personal_id, nombre, moneda_referencia, zona_horaria, fecha_inicio, activo)
                VALUES (:tipo, :propietario_personal_id, :nombre, :moneda_referencia, :zona_horaria, :fecha_inicio, :activo)';

        $stmt = $db->pdo()->prepare($sql);
        $stmt->bindValue(':tipo', strtoupper((string) $payload['tipo']));

        $ownerId = $payload['propietario_personal_id'] ?? null;
        if ($ownerId === null || $ownerId === '' || (int) $ownerId === 0) {
            $stmt->bindValue(':propietario_personal_id', null, \PDO::PARAM_NULL);
        } else {
            $stmt->bindValue(':propietario_personal_id', (int) $ownerId, \PDO::PARAM_INT);
        }

        $stmt->bindValue(':nombre', trim((string) $payload['nombre']));
        $stmt->bindValue(':moneda_referencia', strtoupper((string) $payload['moneda_referencia']));
        $stmt->bindValue(':zona_horaria', (string) ($payload['zona_horaria'] ?? 'America/Ciudad_Juarez'));
        $stmt->bindValue(':fecha_inicio', (string) $payload['fecha_inicio']);
        $stmt->bindValue(':activo', !empty($payload['activo']) ? 1 : 0, \PDO::PARAM_INT);

        $stmt->execute();

        return (int) $db->pdo()->lastInsertId();
    }

    private function database(): Database
    {
        $config = require __DIR__ . '/../../config/app.php';
        return new Database($config['db']);
    }
}
