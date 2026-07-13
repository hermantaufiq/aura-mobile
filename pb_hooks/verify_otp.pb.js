// pb_hooks/verify_otp.pb.js
// Endpoint server-side untuk verifikasi OTP
// Menggunakan $app.dao() yang punya akses admin — bypass listRule

routerAdd("POST", "/api/verify-otp", (c) => {
    // Coba baca dari form values (x-www-form-urlencoded) - paling reliable di PocketBase JSVM
    let email = c.formValue("email") || "";
    let inputOtp = c.formValue("otp") || "";

    // Fallback ke query params
    if (!email) email = c.queryParam("email") || "";
    if (!inputOtp) inputOtp = c.queryParam("otp") || "";

    // Fallback ke request body (JSON)
    if (!email || !inputOtp) {
        try {
            const info = $apis.requestInfo(c);
            if (info && info.body) {
                email = email || info.body["email"] || "";
                inputOtp = inputOtp || info.body["otp"] || "";
            }
        } catch (e) {
            console.log("[verify-otp] body parse error: " + e);
        }
    }

    console.log("[verify-otp] email='" + email + "' otp='" + inputOtp + "'");

    if (!email || !inputOtp) {
        return c.json(400, { success: false, message: "email and otp are required" });
    }

    try {
        // $app.dao() punya akses admin — bypass listRule sepenuhnya
        let record;
        try {
            record = $app.dao().findFirstRecordByData("users", "email", email.toLowerCase());
        } catch (e) {
            console.log("[verify-otp] User not found or error: " + e);
            return c.json(200, { success: false, message: "User tidak ditemukan" });
        }

        if (!record) {
            console.log("[verify-otp] No user found for email: " + email);
            return c.json(200, { success: false, message: "User tidak ditemukan" });
        }
        const dbOtp = record.getString("otp_code") || "";

        console.log("[verify-otp] DB OTP: '" + dbOtp + "' | Input: '" + inputOtp + "' | Match: " + (dbOtp === inputOtp));

        if (dbOtp === "" || dbOtp !== inputOtp) {
            return c.json(200, { success: false, message: "Kode OTP tidak valid" });
        }

        // OTP cocok — tandai verified dan hapus OTP
        record.set("is_verified", true);
        record.set("otp_code", "");
        $app.dao().saveRecord(record);

        console.log("[verify-otp] ✅ Verified: " + email);
        return c.json(200, { success: true, message: "OTP verified" });

    } catch (err) {
        console.log("[verify-otp] Error: " + err);
        return c.json(500, { success: false, message: "Server error: " + err });
    }
});
