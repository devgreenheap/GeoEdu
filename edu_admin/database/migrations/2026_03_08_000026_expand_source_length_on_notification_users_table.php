<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasTable('notification_users') || !Schema::hasColumn('notification_users', 'source')) {
            return;
        }

        $driver = DB::getDriverName();
        if ($driver === 'mysql') {
            DB::statement("ALTER TABLE notification_users MODIFY COLUMN source VARCHAR(100) NULL");
        } elseif ($driver === 'pgsql') {
            DB::statement("ALTER TABLE notification_users ALTER COLUMN source TYPE VARCHAR(100)");
        } elseif ($driver === 'sqlsrv') {
            DB::statement("ALTER TABLE notification_users ALTER COLUMN source NVARCHAR(100) NULL");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (!Schema::hasTable('notification_users') || !Schema::hasColumn('notification_users', 'source')) {
            return;
        }

        $driver = DB::getDriverName();
        if ($driver === 'mysql') {
            DB::statement("ALTER TABLE notification_users MODIFY COLUMN source VARCHAR(30) NULL");
        } elseif ($driver === 'pgsql') {
            DB::statement("ALTER TABLE notification_users ALTER COLUMN source TYPE VARCHAR(30)");
        } elseif ($driver === 'sqlsrv') {
            DB::statement("ALTER TABLE notification_users ALTER COLUMN source NVARCHAR(30) NULL");
        }
    }
};

