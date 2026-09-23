<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserRoleRequests extends Model
{
    use HasFactory;

    public $table = 'tbl_user_role_requests';

    public function user()
    {
        return $this->belongsTo(Users::class, 'user_id');
    }
}
