<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database;

final class AccountModel
{
    public function listBySpace(int $spaceId, int $limit): array
    {
        $db = $this->database();

        $sql = 'SELECT c.id, c.espacio_id, c.moneda, c.naturaleza, c.tipo, c.nombre, c.institucion, c.ultimos_cuatro, c.archivada_en,
                       c.cuenta_contable_id, cc.activo AS cuenta_contable_activa
                FROM cuentas c
                JOIN cuentas_contables cc ON cc.id = c.cuenta_contable_id
                WHERE c.espacio_id = :space_id
                ORDER BY c.id DESC
                LIMIT :limit';

        $stmt = $db->pdo()->prepare($sql);
        $stmt->bindValue(':space_id', $spaceId, \PDO::PARAM_INT);
        $stmt->bindValue(':limit', $limit, \PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    public function create(array $payload): array
    {
        $db = $this->database();
        $pdo = $db->pdo();

        $pdo->beginTransaction();
        try {
            $sqlContable = 'INSERT INTO cuentas_contables (espacio_id, moneda, nombre, tipo, activo)
                            VALUES (:espacio_id, :moneda, :nombre, :tipo, 1)';
            $stmtContable = $pdo->prepare($sqlContable);
            $stmtContable->bindValue(':espacio_id', (int) $payload['espacio_id'], \PDO::PARAM_INT);
            $stmtContable->bindValue(':moneda', strtoupper((string) $payload['moneda']));
            $stmtContable->bindValue(':nombre', trim((string) $payload['nombre']));
            $stmtContable->bindValue(':tipo', strtoupper((string) $payload['naturaleza']));
            $stmtContable->execute();

            $contableId = (int) $pdo->lastInsertId();

            $sqlCuenta = 'INSERT INTO cuentas (espacio_id, moneda, cuenta_contable_id, naturaleza, tipo, nombre, institucion, ultimos_cuatro)
                         VALUES (:espacio_id, :moneda, :cuenta_contable_id, :naturaleza, :tipo, :nombre, :institucion, :ultimos_cuatro)';
            $stmtCuenta = $pdo->prepare($sqlCuenta);
            $stmtCuenta->bindValue(':espacio_id', (int) $payload['espacio_id'], \PDO::PARAM_INT);
            $stmtCuenta->bindValue(':moneda', strtoupper((string) $payload['moneda']));
            $stmtCuenta->bindValue(':cuenta_contable_id', $contableId, \PDO::PARAM_INT);
            $stmtCuenta->bindValue(':naturaleza', strtoupper((string) $payload['naturaleza']));
            $stmtCuenta->bindValue(':tipo', strtoupper((string) $payload['tipo']));
            $stmtCuenta->bindValue(':nombre', trim((string) $payload['nombre']));

            $institucion = trim((string) ($payload['institucion'] ?? ''));
            if ($institucion === '') {
                $stmtCuenta->bindValue(':institucion', null, \PDO::PARAM_NULL);
            } else {
                $stmtCuenta->bindValue(':institucion', $institucion);
            }

            $ultimosCuatro = trim((string) ($payload['ultimos_cuatro'] ?? ''));
            if ($ultimosCuatro === '') {
                $stmtCuenta->bindValue(':ultimos_cuatro', null, \PDO::PARAM_NULL);
            } else {
                $stmtCuenta->bindValue(':ultimos_cuatro', $ultimosCuatro);
            }

            $stmtCuenta->execute();
            $cuentaId = (int) $pdo->lastInsertId();

            $pdo->commit();

            return [
                'cuenta_id' => $cuentaId,
                'cuenta_contable_id' => $contableId,
            ];
        } catch (\Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            throw $e;
        }
    }

    private function database(): Database
    {
        $config = require __DIR__ . '/../../config/app.php';
        return new Database($config['db']);
    }
}
