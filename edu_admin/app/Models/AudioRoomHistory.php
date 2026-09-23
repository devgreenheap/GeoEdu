<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AudioRoomHistory extends Model
{
    use HasFactory;

    public $table = 'tbl_audio_room_history';

    public function host()
    {
        return $this->hasOne(Users::class, 'id', 'host_id');
    }
}
