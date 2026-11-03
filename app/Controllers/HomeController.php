<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Controller;
use App\Models\HealthModel;
use Throwable;

final class HomeController extends Controller
{
    public function index(): void
    {
        $this->view('home', [
            'title' => 'Finanzas Personales - Fase 1',
        ]);
    }

    public function health(): void
    {
        try {
            $model = new HealthModel();
            $ok = $model->databaseOk();
            $this->json(['status' => $ok ? 'ok' : 'degraded']);
        } catch (Throwable $e) {
            $this->json(['status' => 'down', 'error' => 'database_unavailable'], 503);
        }
    }
}
