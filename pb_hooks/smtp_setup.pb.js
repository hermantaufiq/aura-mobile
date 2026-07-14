// pb_hooks/smtp_setup.pb.js
// Manual endpoint to trigger SMTP setup

routerAdd("GET", "/api/setup-smtp", (c) => {
    try {
        const smtpPass   = $os.getenv("PB_SMTP_PASSWORD") || "";
        if (!smtpPass) {
            return c.json(400, { "error": "PB_SMTP_PASSWORD not found in env!" });
        }

        const smtpHost   = $os.getenv("PB_SMTP_HOST")           || "smtp.gmail.com";
        const smtpPort   = parseInt($os.getenv("PB_SMTP_PORT")   || "587");
        const smtpUser   = $os.getenv("PB_SMTP_USERNAME")        || "hermantaufiq12@gmail.com";
        const smtpTls    = ($os.getenv("PB_SMTP_TLS")            || "false") === "true";
        const smtpAuth   = $os.getenv("PB_SMTP_AUTH_METHOD")     || "plain";
        const senderAddr = $os.getenv("PB_SMTP_SENDER_ADDRESS")  || "hermantaufiq12@gmail.com";
        const senderName = $os.getenv("PB_SMTP_SENDER_NAME")     || "AURA Assistant";

        const settings = $app.settings();

        settings.smtp.enabled    = true;
        settings.smtp.host       = smtpHost;
        settings.smtp.port       = smtpPort;
        settings.smtp.username   = smtpUser;
        settings.smtp.password   = smtpPass;
        settings.smtp.tls        = smtpTls;
        settings.smtp.authMethod = smtpAuth;

        settings.meta.senderAddress = senderAddr;
        settings.meta.senderName    = senderName;

        $app.dao().saveSettings(settings);

        return c.json(200, { 
            "status": "success",
            "message": "SMTP configured",
            "host": smtpHost,
            "user": smtpUser
        });
    } catch (err) {
        return c.json(500, { "error": String(err) });
    }
});
