<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Verification Code</title>
</head>
<body style="margin:0;padding:0;background-color:#f4f4f5;font-family:Arial,Helvetica,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:30px 0;">
        <tr>
            <td align="center">
                <table role="presentation" width="420" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:12px;padding:32px;">
                    <tr>
                        <td style="text-align:center;">
                            <h2 style="margin:0 0 16px;color:#1a1a1a;">{{ env('APP_NAME', 'GeoEdu') }}</h2>
                            <p style="color:#555;font-size:15px;margin:0 0 24px;">Use the code below to verify your identity.</p>
                            <div style="font-size:32px;font-weight:700;letter-spacing:8px;color:#FF7A00;background:#fff4ec;padding:16px 0;border-radius:8px;">
                                {{ $otp }}
                            </div>
                            <p style="color:#888;font-size:13px;margin:24px 0 0;">This code expires in {{ $expireMinutes }} minutes. If you didn't request this, you can safely ignore this email.</p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
