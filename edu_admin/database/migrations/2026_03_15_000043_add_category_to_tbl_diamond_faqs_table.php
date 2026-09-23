<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('tbl_diamond_faqs')) {
            return;
        }

        if (!Schema::hasColumn('tbl_diamond_faqs', 'category')) {
            Schema::table('tbl_diamond_faqs', function (Blueprint $table) {
                $table->string('category', 50)->default('diamond')->after('id');
            });
        }

        DB::table('tbl_diamond_faqs')
            ->whereNull('category')
            ->orWhere('category', '')
            ->update(['category' => 'diamond']);
    }

    public function down(): void
    {
        if (Schema::hasTable('tbl_diamond_faqs') && Schema::hasColumn('tbl_diamond_faqs', 'category')) {
            Schema::table('tbl_diamond_faqs', function (Blueprint $table) {
                $table->dropColumn('category');
            });
        }
    }
};
