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
        if (!Schema::hasTable('tbl_live_stream_comments')) {
            Schema::create('tbl_live_stream_comments', function (Blueprint $table) {
                $table->id();
                $table->string('live_stream_id');
                $table->integer('sender_id');
                $table->integer('receiver_id')->nullable();
                $table->text('comment')->nullable();
                $table->string('comment_type', 30);
                $table->integer('gift_id')->nullable();
                $table->timestamps();

                $table->index(['live_stream_id', 'created_at'], 'idx_live_stream_id_created_at');
                $table->index(['comment_type', 'created_at'], 'idx_comment_type_created_at');
                $table->index('sender_id');
                $table->index('receiver_id');
                $table->index('gift_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_live_stream_comments')) {
            Schema::dropIfExists('tbl_live_stream_comments');
        }
    }
};
