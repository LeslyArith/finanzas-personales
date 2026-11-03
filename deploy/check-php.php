<?php

declare(strict_types=1);

$required = ['PDO', 'pdo_mysql', 'mbstring'];
$loaded = array_map('strtolower', get_loaded_extensions());
$missing = [];

foreach ($required as $ext) {
    if (!in_array(strtolower($ext), $loaded, true)) {
        $missing[] = $ext;
    }
}

if ($missing !== []) {
    echo 'PHP_CHECK=FAIL' . PHP_EOL;
    echo 'MISSING=' . implode(',', $missing) . PHP_EOL;
    exit(1);
}

echo 'PHP_CHECK=OK' . PHP_EOL;
echo 'PHP_VERSION=' . PHP_VERSION . PHP_EOL;
