// pb_hooks/test.pb.js
/// <reference path="../pb_data/types.d.ts" />

// Reset admin endpoint (untuk development)
routerAdd("GET", "/api/reset-admin", (c) => {
  const email = "aura@gmail.com";
  const password = "aura123?";
  
  try {
    let user;
    try {
      user = $app.dao().findFirstRecordByData("users", "email", email);
      user.setPassword(password);
      // Pastikan role admin tetap terjaga
      if (user.get("role") !== "admin") {
        user.set("role", "admin");
      }
      $app.dao().saveRecord(user);
      return c.json(200, { "status": "updated", "email": email, "role": user.get("role") });
    } catch (e) {
      // Create new user
      const collection = $app.dao().findCollectionByNameOrId("users");
      user = new Record(collection);
      user.set("email", email);
      user.set("emailVisibility", true);
      user.setPassword(password);
      user.set("name", "Aura Admin");
      user.set("role", "admin");
      user.set("is_verified", true);
      $app.dao().saveRecord(user);
      return c.json(200, { "status": "created", "email": email, "role": "admin" });
    }
  } catch (err) {
    return c.json(500, { "error": err.message });
  }
});

// TEST ENDPOINT to verify SMTP settings
routerAdd("GET", "/api/check-smtp", (c) => {
    try {
        const settings = $app.settings();
        return c.json(200, {
            "smtp_enabled": settings.smtp.enabled,
            "smtp_host": settings.smtp.host,
            "smtp_port": settings.smtp.port,
            "smtp_user": settings.smtp.username,
            "smtp_tls": settings.smtp.tls,
            "smtp_auth": settings.smtp.authMethod,
            "sender_email": settings.meta.senderAddress,
        });
    } catch (err) {
        return c.json(500, { "error": String(err) });
    }
});
