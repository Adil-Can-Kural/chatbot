<?php

namespace App\Http\Controllers;

use App\Models\Message;
use App\Models\Room;
use App\Events\SendMessage;
use App\Http\Requests\StoreMessageRequest;
use App\Http\Requests\UpdateMessageRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;

class MessageController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index(Room $room)
    {
        try {
            $messages = $room->messages()->with(['reads.user'])->get();
            return response()->json([
                'messages' => $messages
            ]);
        } catch (\Exception $e) {
            Log::error('Mesaj listesi alınırken hata: ' . $e->getMessage());
            return response()->json(['error' => 'Mesajlar alınamadı'], 500);
        }
    }

    /**
     * Show the form for creating a new resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Room  $room
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request, Room $room)
    {
        try {
            $request->validate([
                'message' => 'required|string'
            ]);

            $message = $room->messages()->create([
                'message' => $request->message,
                'user_id' => auth()->id(),
                'user_name' => auth()->user()->name,
                'sender_id' => auth()->id(),
                'reads' => [],
            ]);

            $room->update([
                'last_message_id' => $message->id
            ]);

            event(new SendMessage($message, $room));

            return response()->json([
                'data' => [
                    'message' => $message
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Mesaj gönderilirken hata: ' . $e->getMessage());
            return response()->json(['error' => 'Mesaj gönderilemedi'], 500);
        }
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\Message  $message
     * @return \Illuminate\Http\Response
     */
    public function show(Message $message)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  \App\Models\Message  $message
     * @return \Illuminate\Http\Response
     */
    public function edit(Message $message)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \App\Http\Requests\UpdateMessageRequest  $request
     * @param  \App\Models\Message  $message
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, Room $room, Message $message)
    {
        try {
            // Mesajın sahibi olup olmadığını kontrol et
            if ($message->user_id !== auth()->id()) {
                return response()->json(['error' => 'Bu mesajı düzenleme yetkiniz yok.'], 403);
            }

            // Dosya içeren mesajlar düzenlenemez
            if ($message->file_path) {
                return response()->json(['error' => 'Dosya içeren mesajlar düzenlenemez.'], 400);
            }

            $request->validate([
                'message' => 'required|string'
            ]);

            $message->update([
                'message' => $request->message
            ]);

            // Odadaki son mesaj bu ise, onu da güncelle
            if ($room->last_message_id === $message->id) {
                $room->update([
                    'last_message_id' => $message->id
                ]);
            }

            // Mesaj güncellendiğinde olayı tetikle
            event(new SendMessage($message, $room));

            return response()->json([
                'success' => true,
                'data' => [
                    'message' => $message
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Mesaj güncellenirken hata: ' . $e->getMessage());
            return response()->json(['error' => 'Mesaj güncellenemedi: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\Message  $message
     * @return \Illuminate\Http\Response
     */
    public function destroy(Room $room, Message $message)
    {
        try {
            // Mesajın sahibi olup olmadığını kontrol et
            if ($message->user_id !== auth()->id()) {
                return response()->json(['error' => 'Bu mesajı silme yetkiniz yok.'], 403);
            }

            // Dosya içeren mesajlarda dosyayı da sil
            if ($message->file_path && Storage::disk('public')->exists($message->file_path)) {
                Storage::disk('public')->delete($message->file_path);
            }

            // Mesajı sil
            $message->delete();

            // Odanın son mesajı bu ise, son mesajı güncelle
            if ($room->last_message_id === $message->id) {
                $lastMessage = $room->messages()->latest()->first();
                $room->update([
                    'last_message_id' => $lastMessage ? $lastMessage->id : null
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Mesaj başarıyla silindi.'
            ]);
        } catch (\Exception $e) {
            Log::error('Mesaj silinirken hata: ' . $e->getMessage());
            return response()->json(['error' => 'Mesaj silinemedi: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Upload a file to the room.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Room  $room
     * @return \Illuminate\Http\Response
     */
    public function uploadFile(Request $request, Room $room)
    {
        try {
            $request->validate([
                'file' => 'required|file|max:10240', // 10MB maksimum
            ]);

            $file = $request->file('file');
            $fileName = time() . '_' . Str::random(10) . '.' . $file->getClientOriginalExtension();
            $filePath = $file->storeAs('uploads/files', $fileName, 'public');

            $fileUrl = Storage::url($filePath);
            $fileType = $file->getClientOriginalExtension();
            $fileSize = $file->getSize();
            $originalName = $file->getClientOriginalName();

            // Dosya türüne göre mesaj içeriği oluştur
            $messageContent = "[Dosya] $originalName";

            $message = $room->messages()->create([
                'message' => $messageContent,
                'user_id' => auth()->id(),
                'user_name' => auth()->user()->name,
                'sender_id' => auth()->id(),
                'file_path' => $filePath,
                'file_name' => $originalName,
                'file_type' => $fileType,
                'file_size' => $fileSize,
                'reads' => [],
            ]);

            $room->update([
                'last_message_id' => $message->id
            ]);

            event(new SendMessage($message, $room));

            return response()->json([
                'success' => true,
                'data' => [
                    'message' => $message,
                    'file_url' => $fileUrl
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Dosya yüklenirken hata: ' . $e->getMessage());
            return response()->json(['error' => 'Dosya yüklenemedi: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Upload an audio file to the room.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Room  $room
     * @return \Illuminate\Http\Response
     */
    public function uploadAudio(Request $request, Room $room)
    {
        try {
            $request->validate([
                'audio' => 'required|file|max:10240', // 10MB maksimum
            ]);

            $file = $request->file('audio');
            $fileName = time() . '_' . Str::random(10) . '.wav';
            $filePath = $file->storeAs('uploads/audio', $fileName, 'public');

            $fileUrl = Storage::url($filePath);
            $messageContent = "[Ses Kaydı]";

            $message = $room->messages()->create([
                'message' => $messageContent,
                'user_id' => auth()->id(),
                'user_name' => auth()->user()->name,
                'sender_id' => auth()->id(),
                'file_path' => $filePath,
                'file_name' => 'Ses Kaydı',
                'file_type' => 'audio',
                'file_size' => $file->getSize(),
                'reads' => [],
            ]);

            $room->update([
                'last_message_id' => $message->id
            ]);

            event(new SendMessage($message, $room));

            return response()->json([
                'success' => true,
                'data' => [
                    'message' => $message,
                    'file_url' => $fileUrl
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Ses kaydı yüklenirken hata: ' . $e->getMessage());
            return response()->json(['error' => 'Ses kaydı yüklenemedi: ' . $e->getMessage()], 500);
        }
    }
}
