<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Controller;
use App\Models\AccountModel;
use InvalidArgumentException;
use PDOException;
use Throwable;

final class AccountController extends Controller
{
    public function index(): void
    {
        try {
            $spaceId = (int) ($_GET['espacio_id'] ?? 0);
            if ($spaceId <= 0) {
                throw new InvalidArgumentException('espacio_id_required');
            }

            $limit = (int) ($_GET['limit'] ?? 50);
            $limit = max(1, min(200, $limit));

            $model = new AccountModel();
            $rows = $model->listBySpace($spaceId, $limit);

            $this->json(['rows' => $rows]);
        } catch (InvalidArgumentException $e) {
            $this->json(['error' => $e->getMessage()], 422);
        } catch (Throwable $e) {
            $this->json(['error' => 'account_list_failed'], 500);
        }
    }

    public function store(): void
    {
        try {
            $payload = $this->inputJson();
            $this->validatePayload($payload);

            $model = new AccountModel();
            $result = $model->create($payload);

            $this->json(['ok' => true] + $result, 201);
        } catch (InvalidArgumentException $e) {
            $this->json(['error' => $e->getMessage()], 422);
        } catch (PDOException $e) {
            $this->json(['error' => 'account_create_failed'], 422);
        } catch (Throwable $e) {
            $this->json(['error' => 'account_create_failed'], 500);
        }
    }

    private function validatePayload(array $payload): void
    {
        if ((int) ($payload['espacio_id'] ?? 0) <= 0) {
            throw new InvalidArgumentException('espacio_id_invalid');
        }

        $moneda = strtoupper(trim((string) ($payload['moneda'] ?? '')));
        if (!preg_match('/^[A-Z]{3}$/', $moneda)) {
            throw new InvalidArgumentException('moneda_invalid');
        }

        $naturaleza = strtoupper(trim((string) ($payload['naturaleza'] ?? '')));
        if (!in_array($naturaleza, ['ACTIVO', 'PASIVO'], true)) {
            throw new InvalidArgumentException('naturaleza_invalid');
        }

        $tipo = strtoupper(trim((string) ($payload['tipo'] ?? '')));
        if ($tipo === '' || mb_strlen($tipo) > 30) {
            throw new InvalidArgumentException('tipo_invalid');
        }

        $nombre = trim((string) ($payload['nombre'] ?? ''));
        if ($nombre === '' || mb_strlen($nombre) > 120) {
            throw new InvalidArgumentException('nombre_invalid');
        }

        $ultimosCuatro = trim((string) ($payload['ultimos_cuatro'] ?? ''));
        if ($ultimosCuatro !== '' && !preg_match('/^[0-9]{4}$/', $ultimosCuatro)) {
            throw new InvalidArgumentException('ultimos_cuatro_invalid');
        }
    }
}
