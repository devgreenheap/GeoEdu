<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RedeemRequests extends Model
{
    use HasFactory;
    public $table = "tbl_redeem_request";
    protected $guarded = [];

    public function user()
    {
        return $this->hasOne(Users::class, 'id', 'user_id');
    }
}
