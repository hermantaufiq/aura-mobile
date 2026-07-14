// pb_hooks/send_otp.pb.js
// Compatible with PocketBase v0.22.x
// Uses Brevo HTTP API to bypass Railway SMTP blocks (port 587)

function sendBrevoEmail(toEmail, subject, htmlContent) {
    const apiKey = $os.getenv("BREVO_API_KEY") || "";
    
    if (!apiKey) {
        console.log("❌ [AURA OTP] BREVO_API_KEY not found in env!");
        return;
    }

    try {
        const payload = {
            sender: { 
                name: "AURA Assistant", 
                email: "hermantaufiq12@gmail.com" 
            },
            to: [{ email: toEmail }],
            subject: subject,
            htmlContent: htmlContent
        };

        const res = $http.send({
            url: "https://api.brevo.com/v3/smtp/email",
            method: "POST",
            body: JSON.stringify(payload),
            headers: {
                "api-key": apiKey,
                "content-type": "application/json",
                "accept": "application/json"
            },
            timeout: 10 // 10 seconds timeout max so it doesn't hang forever
        });

        if (res.statusCode >= 200 && res.statusCode < 300) {
            console.log("✅ [AURA OTP] Email sent successfully via Brevo API to " + toEmail);
        } else {
            console.log("❌ [AURA OTP] Failed Brevo API: " + res.statusCode + " " + res.raw);
        }
    } catch (err) {
        console.log("❌ [AURA OTP] Exception sending Brevo API: " + err);
    }
}

// Hook after user creation — send OTP email
onRecordAfterCreateRequest((e) => {
    const record = e.record;
    const otp = record.get("otp_code") || "";
    const email = record.get("email") || "";

    if (otp && email) {
        const html = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                <h2 style="color: #6C5CE7; text-align: center;">Verifikasi Akun AURA</h2>
                <p>Halo,</p>
                <p>Terima kasih telah mendaftar di AURA - AI Personal Assistant. Berikut adalah kode OTP Anda:</p>
                <div style="background-color: #f9f9f9; padding: 15px; text-align: center; border-radius: 5px; margin: 20px 0;">
                    <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #6C5CE7;">${otp}</span>
                </div>
                <p>Kode ini berlaku selama 5 menit. Jangan bagikan kode ini kepada siapapun.</p>
                <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                <p style="font-size: 12px; color: #888; text-align: center;">Email ini dikirim secara otomatis oleh sistem AURA via Brevo HTTP API.</p>
            </div>
        `;
        sendBrevoEmail(email, "Kode OTP AURA Anda", html);
    }
}, "users");
