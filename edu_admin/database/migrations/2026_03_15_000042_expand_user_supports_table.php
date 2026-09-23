<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        if (!Schema::hasTable('user_supports')) {
            return;
        }

        Schema::table('user_supports', function (Blueprint $table) {
            if (!Schema::hasColumn('user_supports', 'subject')) {
                $table->string('subject')->nullable()->after('user_id');
            }
            if (!Schema::hasColumn('user_supports', 'message')) {
                $table->text('message')->nullable()->after('subject');
            }
            if (!Schema::hasColumn('user_supports', 'status')) {
                $table->string('status', 20)->default('open')->after('message');
            }
            if (!Schema::hasColumn('user_supports', 'admin_reply')) {
                $table->text('admin_reply')->nullable()->after('status');
            }
            if (!Schema::hasColumn('user_supports', 'admin_name')) {
                $table->string('admin_name')->nullable()->after('admin_reply');
            }
            if (!Schema::hasColumn('user_supports', 'replied_at')) {
                $table->timestamp('replied_at')->nullable()->after('admin_name');
            }
            if (!Schema::hasColumn('user_supports', 'closed_at')) {
                $table->timestamp('closed_at')->nullable()->after('replied_at');
            }
        });
    }

    public function down()
    {
        if (!Schema::hasTable('user_supports')) {
            return;
        }

        Schema::table('user_supports', function (Blueprint $table) {
            $columns = ['subject', 'message', 'status', 'admin_reply', 'admin_name', 'replied_at', 'closed_at'];
            foreach ($columns as $column) {
                if (Schema::hasColumn('user_supports', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
