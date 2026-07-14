// pb_hooks/send_otp.pb.js
// Compatible with PocketBase v0.22.x
// Uses Brevo HTTP API via $http.send() — non-blocking fire-and-forget

// Hook after user creation — send OTP email
onRecordAfterCreateRequest((e) => {
    try {
        const record = e.record;
        const otp = record.get("otp_code") || "";
        const email = record.get("email") || "";

        if (!otp || !email) {
            return; // No OTP to send
        }

        const apiKey = $os.getenv("BREVO_API_KEY") || "";
        if (!apiKey) {
            console.log("⚠️ [AURA OTP] BREVO_API_KEY not set in env — skipping email for: " + email);
            return;
        }

        const html = `<div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
            <h2 style="color: #6C5CE7; text-align: center;">Verifikasi Akun AURA</h2>
            <p>Halo,</p>
            <p>Terima kasih telah mendaftar di AURA. Berikut kode OTP Anda:</p>
            <div style="background-color: #f9f9f9; padding: 15px; text-align: center; border-radius: 5px; margin: 20px 0;">
                <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #6C5CE7;">${otp}</span>
            </div>
            <p>Kode ini berlaku selama 5 menit. Jangan bagikan kepada siapapun.</p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
            <p style="font-size: 12px; color: #888; text-align: center;">AURA AI Personal Assistant</p>
        </div>`;

        const payload = JSON.stringify({
            sender: { name: "AURA Assistant", email: "hermantaufiq12@gmail.com" },
            to: [{ email: email }],
            subject: "Kode OTP AURA Anda",
            htmlContent: html
        });

        try {
            const res = $http.send({
                url: "https://api.brevo.com/v3/smtp/email",
                method: "POST",
                body: payload,
                headers: {
                    "api-key": apiKey,
                    "content-type": "application/json",
                    "accept": "application/json"
                },
                timeout: 15
            });

            if (res.statusCode >= 200 && res.statusCode < 300) {
                console.log("✅ [AURA OTP] Email sent to " + email);
            } else {
                console.log("❌ [AURA OTP] Brevo returned " + res.statusCode + ": " + res.raw);
            }
        } catch (httpErr) {
            // Log but NEVER throw — user creation must succeed
            console.log("❌ [AURA OTP] $http.send error: " + httpErr);
        }

    } catch (outerErr) {
        // Safety net — never crash user creation
        console.log("❌ [AURA OTP] Outer error: " + outerErr);
    }
}, "users");
