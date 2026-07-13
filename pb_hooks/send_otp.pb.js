// pb_hooks/send_otp.pb.js
// Compatible with PocketBase v0.23.x

// Hook after user creation — send OTP email
onRecordAfterCreateSuccess((e) => {
    const record = e.record;
    const otp = record.get("otp_code") || "";
    const email = record.get("email") || "";

    if (otp && email) {
        try {
            const mailer = $app.newMailClient();

            const message = new MailerMessage({
                from: {
                    address: "hermantaufiq12@gmail.com",
                    name: "AURA Assistant",
                },
                to: [{ address: email }],
                subject: "Kode OTP AURA Anda",
                html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                        <h2 style="color: #6C5CE7; text-align: center;">Verifikasi Akun AURA</h2>
                        <p>Halo,</p>
                        <p>Terima kasih telah mendaftar di AURA - AI Personal Assistant. Berikut adalah kode OTP Anda:</p>
                        <div style="background-color: #f9f9f9; padding: 15px; text-align: center; border-radius: 5px; margin: 20px 0;">
                            <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #6C5CE7;">${otp}</span>
                        </div>
                        <p>Kode ini berlaku selama 5 menit. Jangan bagikan kode ini kepada siapapun.</p>
                        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                        <p style="font-size: 12px; color: #888; text-align: center;">Email ini dikirim secara otomatis oleh sistem AURA.</p>
                    </div>
                `
            });

            mailer.send(message);
            console.log("✅ [AURA OTP] Email sent to " + email);
        } catch (err) {
            console.log("❌ [AURA OTP] Error sending email to " + email + ": " + err);
        }
    }
}, "users");

/*
// Hook after user update — resend OTP if it changed
onRecordAfterUpdateRequest((e) => {
    const record = e.record;
    const original = record.original();
    const oldOtp = original ? (original.get("otp_code") || "") : "";
    const newOtp = record.get("otp_code") || "";
    const email = record.get("email") || "";

    if (newOtp && newOtp !== oldOtp && email) {
        try {
            const mailer = $app.newMailClient();

            const message = new MailerMessage({
                from: {
                    address: "hermantaufiq12@gmail.com",
                    name: "AURA Assistant",
                },
                to: [{ address: email }],
                subject: "Kode OTP Baru AURA Anda",
                html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                        <h2 style="color: #6C5CE7; text-align: center;">Verifikasi Ulang Akun AURA</h2>
                        <p>Halo,</p>
                        <p>Berikut adalah kode OTP baru Anda:</p>
                        <div style="background-color: #f9f9f9; padding: 15px; text-align: center; border-radius: 5px; margin: 20px 0;">
                            <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #6C5CE7;">${newOtp}</span>
                        </div>
                        <p>Kode ini berlaku selama 5 menit. Jangan bagikan kode ini kepada siapapun.</p>
                        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                        <p style="font-size: 12px; color: #888; text-align: center;">Email ini dikirim secara otomatis oleh sistem AURA.</p>
                    </div>
                `
            });

            mailer.send(message);
            console.log("✅ [AURA OTP] Resent OTP email sent to " + email);
        } catch (err) {
            console.log("❌ [AURA OTP] Error sending resent OTP to " + email + ": " + err);
        }
    }
}, "users");
*/
