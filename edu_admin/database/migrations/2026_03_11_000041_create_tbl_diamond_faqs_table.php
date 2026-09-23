<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('tbl_diamond_faqs')) {
            Schema::create('tbl_diamond_faqs', function (Blueprint $table) {
                $table->id();
                $table->text('question');
                $table->longText('answer');
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('tbl_diamond_faqs')) {
            Schema::dropIfExists('tbl_diamond_faqs');
        }
    }
};
