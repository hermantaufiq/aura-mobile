// pb_hooks/smtp_config.pb.js
// Auto-configure SMTP using correct PocketBase v0.22.x hook: onAfterBootstrap

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

        // SettingsUpsertForm - correct PocketBase v0.22.x API
        const form = new SettingsUpsertForm($app);

        form.smtp.enabled    = true;
        form.smtp.host       = smtpHost;
        form.smtp.port       = smtpPort;
        form.smtp.username   = smtpUser;
        form.smtp.password   = smtpPass;
        form.smtp.tls        = smtpTls;
        form.smtp.authMethod = smtpAuth;

        form.meta.senderAddress = senderAddr;
        form.meta.senderName    = senderName;

        form.submit();

        console.log("✅ [smtp_config] SMTP saved! " + smtpHost + ":" + smtpPort + " / " + smtpUser);
    } catch (err) {
        console.log("❌ [smtp_config] Error: " + err);
    }
});
