<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;

class Room extends Model
{
    use HasFactory;

    const TYPE_PERSONAL = 1;
    const TYPE_GROUP    = 2;

    protected $fillable = [
        'type',
        'name',
        'is_bot'
    ];

    public function users()
    {
        return $this->belongsToMany(User::class)->withPivot('join_at');
    }

    public function messages()
    {
        return $this->hasMany(Message::class);
    }

    public function typeString(): Attribute
    {
        return Attribute::make(
            get: fn () => $this->type == self::TYPE_PERSONAL ? 'personal' : 'group'
        );
    }

    public function profilePicture(): Attribute
    {
        return Attribute::make(
            get: function () {
                if ($this->type == self::TYPE_PERSONAL) {
                    if ($this->attributes['name'] === 'Elif') {
                        return 'https://i.pravatar.cc/150?img=5';
                    }
                    if ($this->attributes['name'] === 'Nazlı') {
                        return 'https://i.pravatar.cc/150?img=6';
                    }
                    
                    $user = $this->users()->where('id', '<>', Auth::id())->first();
                    return $user ? $user->profile_photo_url : 'https://ui-avatars.com/api/?name='.urlencode($this->name).'&color=7F9CF5&background=EBF4FF';
                }
                
                return 'https://ui-avatars.com/api/?name='.urlencode($this->name).'&color=7F9CF5&background=EBF4FF';
            }
        );
    }

    public function name(): Attribute
    {
        return Attribute::make(
            get: function () {
                if ($this->type == self::TYPE_PERSONAL) {
                    if (!empty($this->attributes['name'])) {
                        return $this->attributes['name'];
                    }
                    
                    $user = $this->users()->where('id', '<>', Auth::id())->first();
                    return $user ? $user->name : 'Yeni Sohbet';
                }
                
                return $this->attributes['name'] ?? 'Yeni Sohbet';
            }
        );
    }

    public function lastMessage(): Attribute
    {
        return Attribute::make(
            get: function () {
                return $this->messages()->orderByDesc('created_at')->first();
            }
        );
    }
}
