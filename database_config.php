<?php
// Bu dosya veritabanı bağlantısını düzeltmek için
// config/database.php dosyasını override eder
return [
    "connections" => [
        "pgsql" => [
            "driver" => "pgsql",
            "host" => "dpg-cvkkl6l6ubrc73fq9b6g-a",
            "port" => 5432,
            "database" => "chat_ake6",
            "username" => "chat_ake6_user",
            "password" => "5mijBS3BEa5bXxFKj0DgF0cUsQOBLkGP",
            "charset" => "utf8",
            "prefix" => "",
            "prefix_indexes" => true,
            "schema" => "public",
            "sslmode" => "prefer",
        ],
    ],
]; 