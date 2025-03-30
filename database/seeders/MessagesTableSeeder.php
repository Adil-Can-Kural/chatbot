<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Room;
use App\Models\User;
use App\Models\Message;
use Carbon\Carbon;

class MessagesTableSeeder extends Seeder
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

        // Odaları al
        $rooms = Room::all();

        if ($rooms->isEmpty()) {
            $this->command->info('Odalar bulunamadı. Önce RoomsTableSeeder çalıştırın.');
            return;
        }

        foreach ($rooms as $room) {
            $users = $room->users;
            
            if ($users->count() < 2) {
                continue;
            }

            $user1 = $users[0];
            $user2 = $users[1];

            // İlk kullanıcıdan mesajlar
            $this->createMessage($room, $user1, 'Merhaba, nasılsın?', Carbon::now()->subHours(2));
            $this->createMessage($room, $user1, 'Bugün hava çok güzel.', Carbon::now()->subHours(1)->subMinutes(50));
            
            // İkinci kullanıcıdan mesajlar
            $this->createMessage($room, $user2, 'İyiyim, teşekkür ederim. Sen nasılsın?', Carbon::now()->subHours(1)->subMinutes(45));
            $this->createMessage($room, $user2, 'Evet, gerçekten güzel bir gün.', Carbon::now()->subHours(1)->subMinutes(40));
            
            // İlk kullanıcıdan daha fazla mesaj
            $this->createMessage($room, $user1, 'Ben de iyiyim. Bugün ne yapıyorsun?', Carbon::now()->subHours(1)->subMinutes(30));
            
            // İkinci kullanıcıdan daha fazla mesaj
            $this->createMessage($room, $user2, 'Biraz kod yazıyorum, sonra dışarı çıkacağım.', Carbon::now()->subHours(1)->subMinutes(25));
            $this->createMessage($room, $user2, 'Sen ne yapıyorsun?', Carbon::now()->subHours(1)->subMinutes(24));
            
            // Son mesaj
            $this->createMessage($room, $user1, 'Ben de biraz çalışıyorum. Sonra belki bir film izlerim.', Carbon::now()->subHours(1));
            
            // Son mesajı güncelle
            $room->update([
                'last_message_id' => $room->messages()->latest()->first()->id
            ]);
        }
    }

    /**
     * Mesaj oluştur
     *
     * @param Room $room
     * @param User $user
     * @param string $message
     * @param Carbon $createdAt
     * @return Message
     */
    private function createMessage(Room $room, User $user, string $message, Carbon $createdAt)
    {
        $msg = new Message();
        $msg->room_id = $room->id;
        $msg->sender_id = $user->id;
        $msg->user_id = $user->id;
        $msg->user_name = $user->name;
        $msg->message = $message;
        $msg->reads = [];
        $msg->created_at = $createdAt;
        $msg->updated_at = $createdAt;
        $msg->save();

        return $msg;
    }
}
