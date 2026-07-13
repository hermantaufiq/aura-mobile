// pb_hooks/resend_otp.pb.js
// Endpoint server-side untuk generate OTP baru, simpan ke DB, dan kirim email
// Menggunakan $app.dao() untuk admin access (bypass listRule) dan form values untuk parsing

routerAdd("POST", "/api/resend-otp", (c) => {
    // Coba baca dari form values (x-www-form-urlencoded) - paling reliable di PocketBase JSVM
    let email = c.formValue("email") || "";

    // Fallback ke query params
    if (!email) email = c.queryParam("email") || "";

    // Fallback ke request body (JSON)
    if (!email) {
        try {
            const info = $apis.requestInfo(c);
            if (info && info.body) {
                email = email || info.body["email"] || "";
            }
        } catch (e) {
            console.log("[resend-otp] body parse error: " + e);
        }
    }

    email = email.trim().toLowerCase();
    console.log("[resend-otp] email='" + email + "'");

    if (!email) {
        return c.json(400, { success: false, message: "email is required" });
    }

    try {
        const records = $app.dao().findRecordsByFilter(
            "users",
            `email = {:email}`,
            "-created",
            1,
            0,
            { email: email }
        );

        if (!records || records.length === 0) {
            console.log("[resend-otp] No user found for email: " + email);
            return c.json(200, { success: false, message: "User tidak ditemukan" });
        }

        const record = records[0];

        // Generate OTP baru (6 digit)
        const otp = String(Math.floor(100000 + Math.random() * 900000));
        console.log("[resend-otp] New OTP: " + otp + " for " + email);

        record.set("otp_code", otp);
        $app.dao().saveRecord(record);

        // Kirim email
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
                            <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #6C5CE7;">${otp}</span>
                        </div>
                        <p>Kode ini berlaku selama 5 menit. Jangan bagikan kode ini kepada siapapun.</p>
                        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                        <p style="font-size: 12px; color: #888; text-align: center;">Email ini dikirim secara otomatis oleh sistem AURA.</p>
                    </div>
                `
            });
            mailer.send(message);
            console.log("[resend-otp] ✅ Email sent to " + email);
        } catch (mailErr) {
            console.log("[resend-otp] ❌ Email error: " + mailErr);
            return c.json(500, { success: false, message: "Gagal mengirim email" });
        }

        return c.json(200, { success: true, message: "OTP baru telah dikirim" });

    } catch (err) {
        console.log("[resend-otp] Error: " + err);
        return c.json(500, { success: false, message: "Server error: " + err });
    }
});
