<?php
// database_override.php dosyası
// Laravel bootstrap sırasında veritabanı yapılandırmasını geçersiz kılar.
if (file_exists(__DIR__ . "/../config/database.custom.php")) {
    $customConfig = require __DIR__ . "/../config/database.custom.php";
    if (isset($customConfig["connections"]["pgsql"])) {
        config(["database.connections.pgsql" => $customConfig["connections"]["pgsql"]]);
    }
} 