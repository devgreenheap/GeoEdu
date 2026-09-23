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
        Schema::create('tbl_live_streams', function (Blueprint $table) {
            $table->id();
            $table->integer('user_id');
            $table->unsignedBigInteger('category_id');
            $table->unsignedBigInteger('sub_category_id');
            $table->unsignedBigInteger('topic_id');
            $table->string('title')->nullable();
            $table->timestamp('started_at');
            $table->timestamp('ended_at')->nullable();
            $table->integer('duration')->default(0);
            $table->tinyInteger('status')->default(1)->comment('1=live,0=ended');
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('tbl_users')->onDelete('cascade');
            $table->foreign('category_id')->references('id')->on('tbl_categories')->onDelete('cascade');
            $table->foreign('sub_category_id')->references('id')->on('tbl_sub_categories')->onDelete('cascade');
            $table->foreign('topic_id')->references('id')->on('tbl_topics')->onDelete('cascade');
            $table->index(['user_id', 'status'], 'idx_live_stream_user_status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_live_streams');
    }
};
