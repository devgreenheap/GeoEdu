<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\Users;

class StateMaster extends Model
{
    use HasFactory;

    protected $table = 'tbl_states';

    protected $fillable = [
        'country_id',
        'name',
        'agent_id',
        'status',
    ];

    public function country()
    {
        return $this->belongsTo(CountryMaster::class, 'country_id');
    }

    public function agent()
    {
        return $this->belongsTo(Users::class, 'agent_id');
    }
}
