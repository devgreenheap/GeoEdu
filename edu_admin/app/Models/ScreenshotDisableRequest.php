<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ScreenshotDisableRequest extends Model
{
    use HasFactory;

    protected $table = 'tbl_screenshot_disable_requests';

    protected $fillable = [
        'user_id',
        'reason',
        'status',
        'approved_by',
        'approved_at',
    ];

    public function user()
    {
        return $this->belongsTo(Users::class, 'user_id');
    }

    public function approver()
    {
        return $this->belongsTo(Users::class, 'approved_by');
    }
}
