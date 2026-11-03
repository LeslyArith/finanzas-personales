<?php

declare(strict_types=1);

$base = $argv[1] ?? 'http://127.0.0.1:8082';
$base = rtrim($base, '/');
$url = $base . '/index.php/health';

$context = stream_context_create([
    'http' => [
        'method' => 'GET',
        'timeout' => 10,
        'ignore_errors' => true,
    ],
]);

$body = @file_get_contents($url, false, $context);
if ($body === false) {
    echo 'WEB_CHECK=FAIL' . PHP_EOL;
    exit(1);
}

$status = 0;
if (!empty($http_response_header[0]) && preg_match('/\s(\d{3})\s/', $http_response_header[0], $m)) {
    $status = (int) $m[1];
}

if ($status < 200 || $status >= 300) {
    echo 'WEB_CHECK=FAIL' . PHP_EOL;
    echo 'HTTP_STATUS=' . $status . PHP_EOL;
    exit(1);
}

echo 'WEB_CHECK=OK' . PHP_EOL;
echo 'HTTP_STATUS=' . $status . PHP_EOL;
