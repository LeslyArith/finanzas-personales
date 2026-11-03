<?php

declare(strict_types=1);

namespace App\Core;

final class Router
{
    /** @var array<int, array{0:string,1:string,2:array{0:class-string,1:string}}> */
    private array $routes = [];

    public function add(string $method, string $path, array $handler): void
    {
        $this->routes[] = [strtoupper($method), $path, $handler];
    }

    public function dispatch(string $method, string $path): void
    {
        $method = strtoupper($method);
        $path = rtrim($path, '/') ?: '/';

        foreach ($this->routes as [$routeMethod, $routePath, $handler]) {
            if ($routeMethod === $method && $routePath === $path) {
                [$class, $action] = $handler;
                $controller = new $class();
                $controller->{$action}();
                return;
            }
        }

        http_response_code(404);
        header('Content-Type: text/plain; charset=utf-8');
        echo '404 Not Found';
    }
}
