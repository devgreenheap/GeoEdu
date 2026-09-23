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
        Schema::table('tbl_users', function (Blueprint $table) {
            if (!Schema::hasColumn('tbl_users', 'diamond_wallet')) {
                $table->unsignedBigInteger('diamond_wallet')->default(0)->after('coin_wallet');
            }
            if (!Schema::hasColumn('tbl_users', 'diamond_collected_lifetime')) {
                $table->unsignedBigInteger('diamond_collected_lifetime')->default(0)->after('diamond_wallet');
            }
            if (!Schema::hasColumn('tbl_users', 'diamond_spent_lifetime')) {
                $table->unsignedBigInteger('diamond_spent_lifetime')->default(0)->after('diamond_collected_lifetime');
            }
            if (!Schema::hasColumn('tbl_users', 'diamond_purchased_lifetime')) {
                $table->unsignedBigInteger('diamond_purchased_lifetime')->default(0)->after('diamond_spent_lifetime');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tbl_users', function (Blueprint $table) {
            if (Schema::hasColumn('tbl_users', 'diamond_purchased_lifetime')) {
                $table->dropColumn('diamond_purchased_lifetime');
            }
            if (Schema::hasColumn('tbl_users', 'diamond_spent_lifetime')) {
                $table->dropColumn('diamond_spent_lifetime');
            }
            if (Schema::hasColumn('tbl_users', 'diamond_collected_lifetime')) {
                $table->dropColumn('diamond_collected_lifetime');
            }
            if (Schema::hasColumn('tbl_users', 'diamond_wallet')) {
                $table->dropColumn('diamond_wallet');
            }
        });
    }
};
