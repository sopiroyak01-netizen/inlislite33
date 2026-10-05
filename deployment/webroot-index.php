<?php

use CodeIgniter\Boot;
use Config\Paths;

/*
 * Front controller for hosts that cannot set their document root to public/.
 * The deployment builder places the non-public application files in
 * __inlislite/ beside this file.
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

require FCPATH . '__inlislite/app/Config/Paths.php';

$paths = new Paths();

require $paths->systemDirectory . '/Boot.php';

exit(Boot::bootWeb($paths));
