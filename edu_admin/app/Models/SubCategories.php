<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SubCategories extends Model
{
    use HasFactory;

    public $table = "tbl_sub_categories";

    public function category()
    {
        return $this->belongsTo(Categories::class, 'category_id', 'id');
    }
}
