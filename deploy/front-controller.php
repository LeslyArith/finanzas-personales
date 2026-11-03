<?php

declare(strict_types=1);

$entryFile = getenv('FP_CONFIG_FILE');
if (!is_string($entryFile) || $entryFile === '') {
    http_response_code(500);
    echo 'FP_CONFIG_FILE is not configured.';
    exit;
}

if (!is_file($entryFile)) {
    http_response_code(500);
    echo 'Config entry file not found.';
    exit;
}

$config = require $entryFile;
if (!is_array($config)) {
    http_response_code(500);
    echo 'Invalid entry config.';
    exit;
}

$appRoot = $config['APP_ROOT'] ?? null;
if (!is_string($appRoot) || $appRoot === '') {
    http_response_code(500);
    echo 'APP_ROOT not defined.';
    exit;
}

$publicPath = $config['PUBLIC_PATH'] ?? ($appRoot . '/public');
if (!is_dir($publicPath)) {
    http_response_code(500);
    echo 'PUBLIC_PATH not found.';
    exit;
}

$index = rtrim($publicPath, '/') . '/index.php';
if (!is_file($index)) {
    http_response_code(500);
    echo 'public/index.php not found.';
    exit;
}

if (!empty($config['FP_ENV_FILE']) && is_string($config['FP_ENV_FILE'])) {
    putenv('FP_ENV_FILE=' . $config['FP_ENV_FILE']);
}

require $index;
