<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class City extends Model
{
    use HasFactory;

    protected $table = 'tbl_cities';

    protected $fillable = [
        'state_id',
        'country_id',
        'name',
        'status',
    ];

    public function state()
    {
        return $this->belongsTo(StateMaster::class, 'state_id');
    }
}
