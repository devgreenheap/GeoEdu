<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'sms' => [
        'api_key' => env('SMS_API_KEY', env('PAY4SMS_API_KEY', env('OTP_SMS_API_KEY', '8f554a8eb2d62b196ac2b1e1a722c8da'))),
        'sender_id' => env('SMS_SENDER_ID', env('OTP_SMS_SENDER', 'GREJEW')),
        'credit' => env('SMS_CREDIT', env('OTP_SMS_CREDIT', 2)),
        'template_id' => env('SMS_TEMPLATE_ID', env('OTP_SMS_TEMPLATE_ID', '1707176154926121089')),
    ],

];
