<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (Schema::hasTable('tbl_users') && !Schema::hasColumn('tbl_users', 'registration_bonus_granted')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $table->tinyInteger('registration_bonus_granted')->default(0)->after('is_verify');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_users') && Schema::hasColumn('tbl_users', 'registration_bonus_granted')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $table->dropColumn('registration_bonus_granted');
            });
        }
    }
};

