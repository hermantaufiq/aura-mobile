// pb_hooks/test.pb.js (appended test-save endpoint)
/// <reference path="../pb_data/types.d.ts" />

routerAdd("GET", "/api/reset-admin", (c) => {
  const email = "aura@gmail.com";
  const password = "aura123?";
  
  try {
    let user;
    try {
      user = $app.dao().findFirstRecordByData("users", "email", email);
      user.setPassword(password);
      if (user.get("role") !== "admin") {
        user.set("role", "admin");
      }
      $app.dao().saveRecord(user);
      return c.json(200, { "status": "updated", "email": email, "role": user.get("role") });
    } catch (e) {
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

routerAdd("GET", "/api/test-save", (c) => {
    const results = [];
    try {
        const settings = $app.settings();
        settings.smtp.enabled = true;
        
        try {
            const form = new SettingsUpsertForm($app);
            form.load(settings);
            form.submit();
            results.push("SettingsUpsertForm with load() worked!");
        } catch(e) {
            results.push("SettingsUpsertForm failed: " + String(e));
        }

        try {
            $app.save(settings);
            results.push("$app.save() worked!");
        } catch (e) {
            results.push("$app.save() failed: " + String(e));
        }
        
        try {
            $app.dao().saveSettings(settings);
            results.push("$app.dao().saveSettings() worked!");
        } catch(e) {
            results.push("$app.dao().saveSettings() failed: " + String(e));
        }

        return c.json(200, { results });
    } catch (err) {
        return c.json(500, { "error": String(err) });
    }
});
routerAdd("GET", "/api/test-getenv", (c) => {
    try {
        const pass = $os.getenv("PB_SMTP_PASSWORD");
        return c.json(200, { "pass_length": pass ? pass.length : 0, "pass": pass });
    } catch(e) {
        return c.json(500, { "error": String(e) });
    }
});

routerAdd("GET", "/api/clear-test-users", (c) => {
    try {
        const records = $app.dao().findRecordsByFilter(
            "users", 
            "role != 'admin' && email != 'aura@gmail.com'",
            "",
            1000,
            0
        );
        
        let deleted = 0;
        records.forEach((r) => {
            try {
                $app.dao().deleteRecord(r);
                deleted++;
            } catch(e) {
                console.log("Skip delete: " + e);
            }
        });

        return c.json(200, { 
            "deleted": deleted,
            "message": "Cleared " + deleted + " test users"
        });
    } catch (err) {
        return c.json(500, { "error": String(err) });
    }
});
