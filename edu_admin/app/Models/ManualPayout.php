<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ManualPayout extends Model
{
    use HasFactory;

    public $table = 'tbl_manual_payouts';
}

