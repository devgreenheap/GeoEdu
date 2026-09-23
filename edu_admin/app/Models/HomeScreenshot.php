<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HomeScreenshot extends Model
{
    use HasFactory;

    protected $table = 'tbl_home_screenshots';

    protected $fillable = ['image', 'sort_order'];
}
