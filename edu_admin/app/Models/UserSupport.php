<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserSupport extends Model
{
    use HasFactory;

    public const STATUS_OPEN = 'open';
    public const STATUS_ANSWERED = 'answered';
    public const STATUS_CLOSED = 'closed';

    protected $table = 'user_supports';

    protected $fillable = [
        'user_id',
        'subject',
        'message',
        'status',
        'admin_reply',
        'admin_name',
        'replied_at',
        'closed_at',
    ];

    public function user()
    {
        return $this->belongsTo(Users::class, 'user_id');
    }
}
