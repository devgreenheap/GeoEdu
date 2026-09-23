<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DiamondFaq extends Model
{
    use HasFactory;

    protected $table = 'tbl_diamond_faqs';

    protected $fillable = [
        'category',
        'question',
        'answer',
    ];
}
