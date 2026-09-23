<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('tbl_signup_otps')) {
            Schema::create('tbl_signup_otps', function (Blueprint $table) {
                $table->id();
                $table->string('mobile_country_code', 10)->nullable();
                $table->string('mobile', 20);
                $table->string('otp', 10);
                $table->timestamp('expires_at');
                $table->timestamp('verified_at')->nullable();
                $table->integer('attempts')->default(0);
                $table->timestamps();

                $table->index('mobile');
                $table->index('expires_at');
                $table->index('verified_at');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('tbl_signup_otps')) {
            Schema::dropIfExists('tbl_signup_otps');
        }
    }
};
