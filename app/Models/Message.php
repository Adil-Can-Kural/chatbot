<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Message extends Model
{
    use HasFactory;
    use SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var string[]
     */
    protected $fillable = [
        'sender_id',
        'room_id',
        'message',
        'user_id',
        'user_name',
        'file_path',
        'file_name',
        'file_type',
        'file_size',
        'reads',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array
     */
    protected $casts = [
        'reads' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function room()
    {
        return $this->belongsTo(Room::class);
    }

    public function reads()
    {
        return $this->hasMany(MessageRead::class, 'message_id');
    }

    /**
     * Check if the message contains a file.
     *
     * @return bool
     */
    public function hasFile()
    {
        return !is_null($this->file_path);
    }

    /**
     * Check if the message contains an image.
     *
     * @return bool
     */
    public function hasImage()
    {
        return $this->hasFile() && in_array($this->file_type, ['jpg', 'jpeg', 'png', 'gif']);
    }

    /**
     * Check if the message contains an audio file.
     *
     * @return bool
     */
    public function hasAudio()
    {
        return $this->hasFile() && $this->file_type === 'audio';
    }
}
