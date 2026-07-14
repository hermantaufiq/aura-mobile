// pb_hooks/smtp_config.pb.js
// Auto-configure SMTP on server start using environment variables
// This runs every time PocketBase starts, ensuring SMTP is always configured

onBeforeServe((e) => {
    try {
        const smtpHost     = $os.getenv("PB_SMTP_HOST")           || "smtp.gmail.com";
        const smtpPort     = parseInt($os.getenv("PB_SMTP_PORT")   || "587");
        const smtpUser     = $os.getenv("PB_SMTP_USERNAME")        || "hermantaufiq12@gmail.com";
        const smtpPass     = $os.getenv("PB_SMTP_PASSWORD")        || "";
        const smtpTls      = ($os.getenv("PB_SMTP_TLS")            || "false") === "true";
        const smtpAuth     = $os.getenv("PB_SMTP_AUTH_METHOD")     || "plain";
        const senderAddr   = $os.getenv("PB_SMTP_SENDER_ADDRESS")  || "hermantaufiq12@gmail.com";
        const senderName   = $os.getenv("PB_SMTP_SENDER_NAME")     || "AURA Assistant";

        if (!smtpPass) {
            console.log("⚠️  [smtp_config] PB_SMTP_PASSWORD not set, skipping SMTP config");
            return;
        }

        const settings = $app.settings();

        // Configure SMTP
        settings.smtp.enabled    = true;
        settings.smtp.host       = smtpHost;
        settings.smtp.port       = smtpPort;
        settings.smtp.username   = smtpUser;
        settings.smtp.password   = smtpPass;
        settings.smtp.tls        = smtpTls;
        settings.smtp.authMethod = smtpAuth;

        // Configure sender info (meta)
        settings.meta.senderName    = senderName;
        settings.meta.senderAddress = senderAddr;

        $app.saveSettings();
        console.log("✅ [smtp_config] SMTP configured: " + smtpHost + ":" + smtpPort + " user=" + smtpUser);
    } catch (err) {
        console.log("❌ [smtp_config] Failed to configure SMTP: " + err);
    }
});
