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
        Schema::table('tbl_user_role_requests', function (Blueprint $table) {
            if (!Schema::hasColumn('tbl_user_role_requests', 'video')) {
                $table->string('video', 500)->nullable()->after('status');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tbl_user_role_requests', function (Blueprint $table) {
            if (!Schema::hasColumn('tbl_user_role_requests', 'video')) {
                $table->dropColumn('video');
            }
        });
    }
};
