<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SiteSetting extends Model
{
    use HasFactory;

    protected $table = 'tbl_site_settings';

    protected $guarded = [];

    /**
     * Get the single website-settings row, creating it if missing.
     */
    public static function current(): SiteSetting
    {
        return static::firstOrCreate(['id' => 1]);
    }
}
