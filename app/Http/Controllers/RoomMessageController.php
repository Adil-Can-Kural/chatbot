<?php

namespace App\Http\Controllers;

use App\Events\ReceiveMessageEvent;
use App\Events\StoreRoomMessageEvent;
use App\Http\Requests\StoreRoomMessageRequest;
use App\Http\Resources\RoomMessageResource;
use App\Models\Message;
use App\Models\Room;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Log;
use Throwable;

class RoomMessageController extends Controller
{
    public function index(Room $room)
    {
        DB::beginTransaction();
        $aiUserId = Config::get('app.ai_user_id');

        if ($aiUserId) {
            // Mark AI messages as read by the current user
            foreach ($room->messages()->where('sender_id', $aiUserId)->with('reads')->get() as $message) {
            if (!in_array(Auth::id(), $message->reads->pluck('user_id')->toArray())) {
                $message->reads()->create([
                    'user_id' => Auth::id(),
                    'read_at' => now()
                ]);
            }
        } else {
            Log::warning('AI User ID (app.ai_user_id) is not configured. Read receipts for AI messages might not work as expected.');
        }
        DB::commit();

        $currentUserId = Auth::id();
        $messagesQuery = $room->messages()->with([
            'user', // Assumes 'user' relationship on Message model is appropriate for display
            'reads' => [
                'user'
            ]
        ]);

        if ($aiUserId) {
            $messagesQuery->where(function ($query) use ($currentUserId, $aiUserId) {
                $query->where('sender_id', $currentUserId) // Messages from the current user
                      ->orWhere('sender_id', $aiUserId);   // Messages from the AI
            });
        } else {
            // Fallback: If AI_USER_ID is not set, only show user's own messages to prevent data leakage.
            // This might not be the desired behavior for all rooms if this controller is used generally.
            // Consider adding a room type check if this controller handles different types of rooms.
            Log::warning('AI User ID (app.ai_user_id) is not configured for room ' . $room->id . '. Filtering to show only current user\'s messages as a precaution.');
            $messagesQuery->where('sender_id', $currentUserId);
        }

        return response()->json([
            'messages' => RoomMessageResource::collection($room->messages()->with([
                'user',
                'reads' => [
                    'user'
                ]
            ])->orderBy('created_at', 'asc')->get())
        ]);
    }

    public function store(Room $room, StoreRoomMessageRequest $request)
    {
        try {
            DB::beginTransaction();

            $message = Message::create([
                'sender_id' => Auth::id(),
                'room_id' => $room->id,
                'message' => $request->message,
            ]);
            broadcast(new StoreRoomMessageEvent($message))->toOthers();

            foreach ($room->users as $user) {
                broadcast(new ReceiveMessageEvent($room, $user));
            }

            DB::commit();

            return response()->json([
                "message" => "message send successfully",
                "data" => [
                    "message" => RoomMessageResource::make($message)
                ]
            ]);
        } catch (Throwable $e) {
            DB::rollBack();

            return response()->json([
                "message" => $e->getMessage()
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }
}
