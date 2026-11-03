<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Controller;
use App\Models\SpaceModel;
use InvalidArgumentException;
use PDOException;
use Throwable;

final class SpaceController extends Controller
{
    public function index(): void
    {
        try {
            $limit = (int) ($_GET['limit'] ?? 20);
            $limit = max(1, min(100, $limit));

            $model = new SpaceModel();
            $rows = $model->list($limit);

            $this->json(['rows' => $rows]);
        } catch (Throwable $e) {
            $this->json(['error' => 'space_list_failed'], 500);
        }
    }

    public function store(): void
    {
        try {
            $payload = $this->inputJson();
            $this->validatePayload($payload);

            $model = new SpaceModel();
            $id = $model->create($payload);

            $this->json(['ok' => true, 'id' => $id], 201);
        } catch (InvalidArgumentException $e) {
            $this->json(['error' => $e->getMessage()], 422);
        } catch (PDOException $e) {
            $this->json(['error' => 'space_create_failed'], 422);
        } catch (Throwable $e) {
            $this->json(['error' => 'space_create_failed'], 500);
        }
    }

    private function validatePayload(array $payload): void
    {
        $tipo = strtoupper(trim((string) ($payload['tipo'] ?? '')));
        if (!in_array($tipo, ['PERSONAL', 'GRUPO'], true)) {
            throw new InvalidArgumentException('tipo_invalid');
        }

        $nombre = trim((string) ($payload['nombre'] ?? ''));
        if ($nombre === '' || mb_strlen($nombre) > 120) {
            throw new InvalidArgumentException('nombre_invalid');
        }

        $moneda = strtoupper(trim((string) ($payload['moneda_referencia'] ?? '')));
        if (!preg_match('/^[A-Z]{3}$/', $moneda)) {
            throw new InvalidArgumentException('moneda_invalid');
        }

        $fecha = (string) ($payload['fecha_inicio'] ?? '');
        $date = \DateTimeImmutable::createFromFormat('Y-m-d', $fecha);
        if (!$date || $date->format('Y-m-d') !== $fecha) {
            throw new InvalidArgumentException('fecha_inicio_invalid');
        }

        $zona = trim((string) ($payload['zona_horaria'] ?? 'America/Ciudad_Juarez'));
        if ($zona === '' || mb_strlen($zona) > 64) {
            throw new InvalidArgumentException('zona_horaria_invalid');
        }

        if ($tipo === 'PERSONAL' && empty($payload['propietario_personal_id'])) {
            throw new InvalidArgumentException('propietario_personal_id_required');
        }
    }
}
