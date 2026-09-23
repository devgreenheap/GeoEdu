<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HomeFeature extends Model
{
    use HasFactory;

    protected $table = 'tbl_home_features';

    protected $fillable = ['icon', 'title', 'description', 'sort_order'];
}
