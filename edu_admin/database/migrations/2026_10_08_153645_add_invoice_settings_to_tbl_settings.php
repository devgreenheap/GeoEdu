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
        Schema::table('tbl_settings', function (Blueprint $table) {
            // Tax Configuration
            $table->tinyInteger('invoice_sgst_enabled')->default(0)->after('updated_at');
            $table->decimal('invoice_sgst_percent', 5, 2)->default(0.00)->after('invoice_sgst_enabled');
            $table->tinyInteger('invoice_cgst_enabled')->default(0)->after('invoice_sgst_percent');
            $table->decimal('invoice_cgst_percent', 5, 2)->default(0.00)->after('invoice_cgst_enabled');
            $table->tinyInteger('invoice_igst_enabled')->default(1)->after('invoice_cgst_percent');
            $table->decimal('invoice_igst_percent', 5, 2)->default(18.00)->after('invoice_igst_enabled');

            // Company Information
            $table->string('invoice_company_name', 191)->default('Greenheap DigiEdu Private Limited')->after('invoice_igst_percent');
            $table->text('invoice_company_address')->nullable()->after('invoice_company_name');
            $table->string('invoice_gstin', 50)->default('29AAGCG1234F1Z5')->after('invoice_company_address');
            $table->string('invoice_hsn_code', 50)->default('998439')->after('invoice_gstin');
            $table->string('invoice_company_email', 100)->default('support@geoedu.com')->after('invoice_hsn_code');
            $table->string('invoice_phone_number', 50)->default('+91 9876543210')->after('invoice_company_email');
            $table->string('invoice_place_of_supply', 100)->default('Tamil Nadu, India')->after('invoice_phone_number');
            $table->string('invoice_company_logo', 255)->nullable()->after('invoice_place_of_supply');
            $table->string('invoice_signature_image', 255)->nullable()->after('invoice_company_logo');

            // Invoice Configuration
            $table->string('invoice_title', 100)->default('Tax Invoice')->after('invoice_signature_image');
            $table->string('invoice_prefix', 50)->default('GEO')->after('invoice_title');
            $table->string('invoice_currency', 20)->default('Rs.')->after('invoice_prefix');
            $table->text('invoice_footer_text')->nullable()->after('invoice_currency');
            $table->text('invoice_terms_text')->nullable()->after('invoice_footer_text');
            $table->string('invoice_signatory_name', 100)->default('GeoEdu Auth')->after('invoice_terms_text');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tbl_settings', function (Blueprint $table) {
            $table->dropColumn([
                'invoice_sgst_enabled',
                'invoice_sgst_percent',
                'invoice_cgst_enabled',
                'invoice_cgst_percent',
                'invoice_igst_enabled',
                'invoice_igst_percent',
                'invoice_company_name',
                'invoice_company_address',
                'invoice_gstin',
                'invoice_hsn_code',
                'invoice_company_email',
                'invoice_phone_number',
                'invoice_place_of_supply',
                'invoice_company_logo',
                'invoice_signature_image',
                'invoice_title',
                'invoice_prefix',
                'invoice_currency',
                'invoice_footer_text',
                'invoice_terms_text',
                'invoice_signatory_name',
            ]);
        });
    }
};
