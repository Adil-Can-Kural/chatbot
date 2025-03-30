<?php

namespace App\Http\Controllers;

use App\Models\Room;
use App\Http\Requests\StoreRoomRequest;
use App\Http\Requests\UpdateRoomRequest;
use App\Http\Resources\AuthUserRoomsResource;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;

class RoomController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        return response()->json([
            'rooms' => AuthUserRoomsResource::collection(Auth::user()->rooms)
        ]);
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        // Oda adını al
        $name = $request->input('name', 'Yeni Sohbet');
        $isBot = $request->input('is_bot', false);

        // Yeni oda oluştur
        $room = Room::create([
            'type' => Room::TYPE_PERSONAL,
            'name' => $name,
            'is_bot' => $isBot
        ]);

        // Kullanıcıyı odaya ekle
        $room->users()->attach(Auth::id(), ['join_at' => now()]);

        return response()->json([
            'success' => true,
            'message' => 'Oda başarıyla oluşturuldu',
            'data' => [
                'room' => $room
            ]
        ]);
    }
}
