<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PkBattleHistory extends Model
{
    use HasFactory;

    public $table = 'tbl_pk_battle_history';

    public function user1()
    {
        return $this->hasOne(Users::class, 'id', 'user1_id');
    }

    public function user2()
    {
        return $this->hasOne(Users::class, 'id', 'user2_id');
    }
}
