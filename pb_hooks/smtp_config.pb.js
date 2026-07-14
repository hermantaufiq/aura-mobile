// pb_hooks/smtp_config.pb.js
// Auto-configure SMTP using PocketBase v0.22 JSVM API

onAfterBootstrap((e) => {
    try {
        console.log("🔧 [smtp_config] onAfterBootstrap - Configuring SMTP...");

        const smtpPass   = $os.getenv("PB_SMTP_PASSWORD") || "";
        if (!smtpPass) {
            console.log("⚠️  [smtp_config] PB_SMTP_PASSWORD not found in env!");
            return;
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

        // Correct API for v0.22
        $app.save(settings);

        console.log("✅ [smtp_config] SMTP saved via $app.save()! " + smtpHost + ":" + smtpPort + " / " + smtpUser);
    } catch (err) {
        console.log("❌ [smtp_config] Error: " + err);
    }
});
