<?php

declare(strict_types=1);

namespace App\Core;

use InvalidArgumentException;

abstract class Controller
{
    protected function view(string $template, array $data = []): void
    {
        extract($data, EXTR_SKIP);
        require __DIR__ . '/../Views/' . $template . '.php';
    }

    protected function json(array $payload, int $statusCode = 200): void
    {
        http_response_code($statusCode);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    protected function inputJson(): array
    {
        $raw = file_get_contents('php://input');
        if ($raw === false || trim($raw) === '') {
            return [];
        }

        $data = json_decode($raw, true);
        if (!is_array($data)) {
            throw new InvalidArgumentException('invalid_json');
        }

        return $data;
    }
}
