// pb_hooks/smtp_config.pb.js
// Auto-configure SMTP on server start using SettingsUpsertForm (correct PocketBase v0.22.x API)

onBeforeServe((e) => {
    try {
        console.log("🔧 [smtp_config] Configuring SMTP settings...");

        const smtpHost   = $os.getenv("PB_SMTP_HOST")           || "smtp.gmail.com";
        const smtpPort   = parseInt($os.getenv("PB_SMTP_PORT")   || "587");
        const smtpUser   = $os.getenv("PB_SMTP_USERNAME")        || "hermantaufiq12@gmail.com";
        const smtpPass   = $os.getenv("PB_SMTP_PASSWORD")        || "";
        const smtpTls    = ($os.getenv("PB_SMTP_TLS")            || "false") === "true";
        const smtpAuth   = $os.getenv("PB_SMTP_AUTH_METHOD")     || "plain";
        const senderAddr = $os.getenv("PB_SMTP_SENDER_ADDRESS")  || "hermantaufiq12@gmail.com";
        const senderName = $os.getenv("PB_SMTP_SENDER_NAME")     || "AURA Assistant";

        if (!smtpPass) {
            console.log("⚠️  [smtp_config] PB_SMTP_PASSWORD not found in env vars!");
            return;
        }

        console.log("🔧 [smtp_config] SMTP Password found, applying settings...");

        // Use SettingsUpsertForm - the correct PocketBase v0.22.x API
        const form = new SettingsUpsertForm($app);

        // Configure SMTP
        form.smtp.enabled    = true;
        form.smtp.host       = smtpHost;
        form.smtp.port       = smtpPort;
        form.smtp.username   = smtpUser;
        form.smtp.password   = smtpPass;
        form.smtp.tls        = smtpTls;
        form.smtp.authMethod = smtpAuth;

        // Configure sender info
        form.meta.senderAddress = senderAddr;
        form.meta.senderName    = senderName;

        // Submit & save to database
        form.submit();

        console.log("✅ [smtp_config] SMTP configured & saved: " + smtpHost + ":" + smtpPort + " user=" + smtpUser);
    } catch (err) {
        console.log("❌ [smtp_config] Failed: " + err);
    }
});
