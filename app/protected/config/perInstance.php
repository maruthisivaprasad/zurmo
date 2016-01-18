<?php
    $language         = 'en';
    $currencyBaseCode = 'USD';
    $theme            = 'default';
    $connectionString = 'mysql:host=localhost;port=3306;dbname=opticaltel';
    $username         = 'root';
    $password         = '';
    $memcacheServers  = array(
                            array(
                                'host'   => '',
                                'port'   => 0,
                                'weight' => 100,
                            ),
                        );
    $adminEmail       = 'er.krishna9@gmail.com';
    $installed = true; // Set to true by the installation process.
    $maintenanceMode  = false; // Set to true during upgrade process or other maintenance tasks.
    $instanceConfig   = array(); //Set any parameters you want to have merged into configuration array.

    $urlManager = array(); // Set any parameters you want to customize url manager.

    if (is_file(INSTANCE_ROOT . '/protected/config/perInstanceConfig.php'))
    {
        require_once INSTANCE_ROOT . '/protected/config/perInstanceConfig.php';
    }
    define('ZURMO_TOKEN', 'e6b5ce4187d9415');

    // Never modify this value below manually or system will not be able to decrypt encrypted passwords.
    define('ZURMO_PASSWORD_SALT', '514ecdb8c04b467');
?>