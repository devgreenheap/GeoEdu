<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        if (Schema::hasTable('tbl_users')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                if (!Schema::hasColumn('tbl_users', 'verification_photo')) {
                    $table->string('verification_photo', 999)->nullable()->after('profile_photo');
                }
            });
            
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        if (Schema::hasTable('tbl_users')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                if (Schema::hasColumn('tbl_users', 'verification_photo')) {
                    $table->dropColumn('verification_photo');
                }
            });
        }
    }
};
