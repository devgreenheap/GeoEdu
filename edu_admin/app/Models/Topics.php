<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Topics extends Model
{
    use HasFactory;

    public $table = "tbl_topics";

    public function category()
    {
        return $this->belongsTo(Categories::class, 'category_id', 'id');
    }

    public function subCategory()
    {
        return $this->belongsTo(SubCategories::class, 'sub_category_id', 'id');
    }
}
