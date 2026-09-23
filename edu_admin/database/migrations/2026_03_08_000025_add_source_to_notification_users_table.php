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
        if (Schema::hasTable('notification_users') && !Schema::hasColumn('notification_users', 'source')) {
            Schema::table('notification_users', function (Blueprint $table) {
                $table->string('source', 30)->nullable()->after('data_id');
                $table->index(['type', 'source'], 'idx_notification_type_source');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('notification_users') && Schema::hasColumn('notification_users', 'source')) {
            Schema::table('notification_users', function (Blueprint $table) {
                $table->dropIndex('idx_notification_type_source');
                $table->dropColumn('source');
            });
        }
    }
};

