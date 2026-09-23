<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GifterReturnWallet extends Model
{
    use HasFactory;

    protected $table = 'tbl_gifter_return_wallets';

    protected $fillable = [
        'user_id',
        'gift_category_id',
        'stars',
    ];
}
