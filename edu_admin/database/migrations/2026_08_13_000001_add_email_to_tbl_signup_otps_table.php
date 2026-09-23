<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('tbl_signup_otps') && Schema::hasColumn('tbl_signup_otps', 'mobile')) {
            DB::statement('ALTER TABLE tbl_signup_otps MODIFY mobile VARCHAR(20) NULL');
        }

        if (!Schema::hasColumn('tbl_signup_otps', 'email')) {
            Schema::table('tbl_signup_otps', function (Blueprint $table) {
                $table->string('email', 255)->nullable()->after('mobile');
                $table->index('email');
            });
        }

        if (!Schema::hasColumn('tbl_signup_otps', 'identity_type')) {
            Schema::table('tbl_signup_otps', function (Blueprint $table) {
                $table->string('identity_type', 10)->default('mobile')->after('email');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('tbl_signup_otps', 'identity_type')) {
            Schema::table('tbl_signup_otps', function (Blueprint $table) {
                $table->dropColumn('identity_type');
            });
        }

        if (Schema::hasColumn('tbl_signup_otps', 'email')) {
            Schema::table('tbl_signup_otps', function (Blueprint $table) {
                $table->dropIndex(['email']);
                $table->dropColumn('email');
            });
        }

        if (Schema::hasTable('tbl_signup_otps') && Schema::hasColumn('tbl_signup_otps', 'mobile')) {
            DB::statement('ALTER TABLE tbl_signup_otps MODIFY mobile VARCHAR(20) NOT NULL');
        }
    }
};
