<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('tbl_screenshot_disable_requests')) {
            Schema::create('tbl_screenshot_disable_requests', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->text('reason');
                $table->tinyInteger('status')->default(0)->comment('0=pending,1=approved');
                $table->unsignedBigInteger('approved_by')->nullable();
                $table->timestamp('approved_at')->nullable();
                $table->timestamps();

                $table->index('user_id');
                $table->index('status');
                $table->index('approved_by');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('tbl_screenshot_disable_requests')) {
            Schema::dropIfExists('tbl_screenshot_disable_requests');
        }
    }
};
