<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('notification_users') || Schema::hasColumn('notification_users', 'language_id')) {
            return;
        }

        Schema::table('notification_users', function (Blueprint $table) {
            $table->unsignedBigInteger('language_id')->nullable()->after('source');
            $table->index(['type', 'language_id'], 'idx_notification_type_language');
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('notification_users') || !Schema::hasColumn('notification_users', 'language_id')) {
            return;
        }

        Schema::table('notification_users', function (Blueprint $table) {
            $table->dropIndex('idx_notification_type_language');
            $table->dropColumn('language_id');
        });
    }
};
