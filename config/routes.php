<?php

declare(strict_types=1);

return [
    ['GET', '/', ['App\\Controllers\\HomeController', 'index']],
    ['GET', '/health', ['App\\Controllers\\HomeController', 'health']],
    ['GET', '/api/espacios', ['App\\Controllers\\SpaceController', 'index']],
    ['POST', '/api/espacios', ['App\\Controllers\\SpaceController', 'store']],
    ['GET', '/api/cuentas', ['App\\Controllers\\AccountController', 'index']],
    ['POST', '/api/cuentas', ['App\\Controllers\\AccountController', 'store']],
];
