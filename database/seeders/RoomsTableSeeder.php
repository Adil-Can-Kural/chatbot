<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Room;
use App\Models\User;

class RoomsTableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // Kullanıcıları al
        $admin = User::where('email', 'admin@admin.com')->first();
        $test = User::where('email', 'test@test.com')->first();
        $wailan = User::where('email', 'wailan@example.com')->first();

        if (!$admin || !$test || !$wailan) {
            $this->command->info('Kullanıcılar bulunamadı. Önce UsersTableSeeder çalıştırın.');
            return;
        }

        // Admin ve Test kullanıcıları arasında bir oda oluştur
        $room1 = Room::create([
            'name' => 'Admin-Test Odası',
            'profile_picture' => 'https://ui-avatars.com/api/?name=Test+User&background=random',
        ]);

        // Admin ve Wailan kullanıcıları arasında bir oda oluştur
        $room2 = Room::create([
            'name' => 'Admin-Wailan Odası',
            'profile_picture' => 'https://ui-avatars.com/api/?name=Wailan+Tirajoh&background=random',
        ]);

        // Test ve Wailan kullanıcıları arasında bir oda oluştur
        $room3 = Room::create([
            'name' => 'Test-Wailan Odası',
            'profile_picture' => 'https://ui-avatars.com/api/?name=Wailan+Tirajoh&background=random',
        ]);

        // Kullanıcıları odalara ekle
        $room1->users()->attach([$admin->id, $test->id]);
        $room2->users()->attach([$admin->id, $wailan->id]);
        $room3->users()->attach([$test->id, $wailan->id]);
    }
}
