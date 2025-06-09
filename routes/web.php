<?php

use App\Events\PrivateWebsocketTest;
use App\Events\PublicWebsocketTest;
use App\Events\WebsocketTest;
use App\Http\Controllers\ApplicationController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\MessageController;
use App\Http\Controllers\NewChatController;
use App\Http\Controllers\RoomController;
use App\Http\Controllers\RoomMessageController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\Route;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/
Route::get('/websocket-test', function() {
    // broadcast(new WebsocketTest('test'));
    broadcast(new PublicWebsocketTest());
    broadcast(new PrivateWebsocketTest());
});

Route::middleware([
    'auth:sanctum',
    config('jetstream.auth_session'),
    'verified',
])->group(function () {
    Route::get('/', [ApplicationController::class, 'index'])->name('application');
    Route::get('/rooms/{room}/messages', [RoomMessageController::class, 'index'])->name('rooms.messages.index');
    Route::post('/rooms/{room}/messages', [RoomMessageController::class, 'store'])->name('rooms.messages.store');

    Route::get('/new-chat/get-users-by-email', [NewChatController::class, 'getUsersByEmail'])->name('new-chat.get-users-by-email');

    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/rooms/{room}/messages', [MessageController::class, 'index'])->name('messages.index');
    Route::post('/rooms/{room}/messages', [MessageController::class, 'store'])->name('messages.store');
    Route::post('/rooms/{room}/upload', [MessageController::class, 'uploadFile'])->name('messages.upload');
    Route::post('/rooms/{room}/upload-audio', [MessageController::class, 'uploadAudio'])->name('messages.upload-audio');
    Route::put('/rooms/{room}/messages/{message}', [MessageController::class, 'update'])->name('messages.update');
    Route::delete('/rooms/{room}/messages/{message}', [MessageController::class, 'destroy'])->name('messages.destroy');
    Route::post('/rooms', [RoomController::class, 'store'])->name('rooms.store');
    Route::post('/new-chat', [NewChatController::class, 'store'])->name('new-chat.store');
});

Route::post('/login', function (Request $request) {
    $request->validate([
        'username' => 'required|exists:users,username',
    ], [
        'username.required' => 'Kullanıcı adı alanı gereklidir.',
        'username.exists' => 'Bu kullanıcı adı sistemde bulunamadı.',
    ]);

    $user = \App\Models\User::where('username', $request->username)->first();
    if ($user) {
        Auth::login($user);
        return response('', 204); // Inertia için
    }

    return back()->withErrors(['username' => 'Giriş başarısız.']);
});
