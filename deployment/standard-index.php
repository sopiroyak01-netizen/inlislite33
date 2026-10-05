<?php

use CodeIgniter\Boot;
use Config\Paths;

/*
 * Front controller for the Standard shared-hosting layout. The deployment
 * builder creates public/ and inlislite-core/ as sibling directories.
 */
$minPhpVersion = '8.2';

if (version_compare(PHP_VERSION, $minPhpVersion, '<')) {
    header('HTTP/1.1 503 Service Unavailable', true, 503);
    echo 'This application requires PHP ' . $minPhpVersion . ' or newer.';
    exit(1);
}

define('FCPATH', __DIR__ . DIRECTORY_SEPARATOR);

if (getcwd() . DIRECTORY_SEPARATOR !== FCPATH) {
    chdir(FCPATH);
}

require FCPATH . '../inlislite-core/app/Config/Paths.php';

$paths = new Paths();

require $paths->systemDirectory . '/Boot.php';

exit(Boot::bootWeb($paths));
