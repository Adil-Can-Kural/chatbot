<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class UsersTableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // Admin kullanıcısı oluştur
        User::create([
            'name' => 'Admin',
            'email' => 'admin@admin.com',
            'password' => Hash::make('123456'),
            'email_verified_at' => now(),
        ]);

        // Test kullanıcısı oluştur
        User::create([
            'name' => 'Test User',
            'email' => 'test@test.com',
            'password' => Hash::make('123456'),
            'email_verified_at' => now(),
        ]);

        // Wailan Tirajoh kullanıcısı oluştur
        User::create([
            'name' => 'Wailan Tirajoh',
            'email' => 'wailan@example.com',
            'password' => Hash::make('123456'),
            'email_verified_at' => now(),
        ]);
    }
}
