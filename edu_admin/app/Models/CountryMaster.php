<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CountryMaster extends Model
{
    use HasFactory;

    protected $table = 'tbl_countries';

    protected $fillable = [
        'name',
        'status',
    ];
}
