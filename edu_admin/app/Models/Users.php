<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Users extends Model
{
    use HasFactory;
    public $table = "tbl_users";

    public function links()
    {
        return $this->hasMany(UserLinks::class, 'user_id', 'id');
    }
    public function stories()
    {
        return $this->hasMany(Story::class, 'user_id', 'id');
    }

    public function level()
    {
        return $this->belongsTo(UserLevels::class, 'level_id');
    }

    public function interests()
    {
        return $this->belongsToMany(Interest::class, 'tbl_user_interests', 'user_id', 'interest_id');
    }

}
