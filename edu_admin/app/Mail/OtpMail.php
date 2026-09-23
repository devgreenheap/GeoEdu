<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class OtpMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $otp;
    public int $expireMinutes;

    public function __construct(string $otp, int $expireMinutes = 10)
    {
        $this->otp = $otp;
        $this->expireMinutes = $expireMinutes;
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Your ' . env('APP_NAME', 'GeoEdu') . ' verification code',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.otp',
            with: [
                'otp' => $this->otp,
                'expireMinutes' => $this->expireMinutes,
            ],
        );
    }

    /**
     * @return array<int, \Illuminate\Mail\Mailables\Attachment>
     */
    public function attachments(): array
    {
        return [];
    }
}
