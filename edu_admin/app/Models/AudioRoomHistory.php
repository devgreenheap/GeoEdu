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
        return $this->belongsTo(Users::class, 'host_id', 'id');
    }

    public function user()
    {
        return $this->belongsTo(Users::class, 'host_id', 'id');
    }
}
