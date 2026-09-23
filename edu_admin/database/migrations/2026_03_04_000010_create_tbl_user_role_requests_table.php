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
        Schema::create('tbl_user_role_requests', function (Blueprint $table) {
            $table->id();
            $table->integer('user_id');
            $table->tinyInteger('request_type')->comment('1=host,2=agent');
            $table->tinyInteger('status')->default(0)->comment('0=pending,1=accepted,2=rejected');
            $table->timestamp('requested_at')->nullable();
            $table->timestamp('action_at')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('tbl_users')->onDelete('cascade');
            $table->index(['user_id', 'request_type', 'status'], 'idx_user_role_req_user_type_status');
            $table->index(['status'], 'idx_user_role_req_status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_user_role_requests');
    }
};
