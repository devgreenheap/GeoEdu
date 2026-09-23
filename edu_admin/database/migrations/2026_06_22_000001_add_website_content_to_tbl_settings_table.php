<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Website (public site) content lives in its own table to avoid the
     * MySQL row-size limit on the already-large tbl_settings table.
     */
    public function up(): void
    {
        if (!Schema::hasTable('tbl_site_settings')) {
            Schema::create('tbl_site_settings', function (Blueprint $table) {
                $table->id();
                // Home - hero
                $table->string('home_hero_title')->nullable();
                $table->text('home_hero_subtitle')->nullable();
                $table->string('home_hero_image')->nullable();
                $table->string('home_app_store_url')->nullable();
                $table->string('home_play_store_url')->nullable();
                // Home - section headings
                $table->string('home_features_title')->nullable();
                $table->text('home_features_subtitle')->nullable();
                $table->string('home_screenshots_title')->nullable();
                $table->text('home_screenshots_subtitle')->nullable();
                // About Us
                $table->longText('about_us')->nullable();
                // Contact Us
                $table->string('contact_email')->nullable();
                $table->string('contact_phone')->nullable();
                $table->text('contact_address')->nullable();
                $table->string('contact_facebook')->nullable();
                $table->string('contact_instagram')->nullable();
                $table->string('contact_twitter')->nullable();
                $table->string('contact_youtube')->nullable();
                $table->timestamps();
            });

            // Seed the single settings row.
            DB::table('tbl_site_settings')->insert([
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        if (!Schema::hasTable('tbl_home_features')) {
            Schema::create('tbl_home_features', function (Blueprint $table) {
                $table->id();
                $table->string('icon')->nullable(); // icon class e.g. "uil-shield-check" or image path
                $table->string('title');
                $table->text('description')->nullable();
                $table->unsignedInteger('sort_order')->default(0);
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('tbl_home_screenshots')) {
            Schema::create('tbl_home_screenshots', function (Blueprint $table) {
                $table->id();
                $table->string('image');
                $table->unsignedInteger('sort_order')->default(0);
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_home_features');
        Schema::dropIfExists('tbl_home_screenshots');
        Schema::dropIfExists('tbl_site_settings');
    }
};
