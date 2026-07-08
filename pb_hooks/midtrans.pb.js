/// <reference path="../pb_data/types.d.ts" />

// ==========================================
// 1. ENDPOINT CHECKOUT (Dipanggil dari Flutter)
// ==========================================
routerAdd("POST", "/api/midtrans/checkout", (c) => {
  // Baca dari environment variable (set di .env atau OS environment)
  // JANGAN hardcode key langsung di sini!
  const MIDTRANS_SERVER_KEY = $os.getenv("MIDTRANS_SERVER_KEY") || "";
  if (!MIDTRANS_SERVER_KEY) {
    throw new BadRequestError("MIDTRANS_SERVER_KEY belum dikonfigurasi di server");
  }

  // Base64 encode manual (PocketBase 0.22 tidak support btoa/$encoding)
  function base64Encode(str) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
    let result = '';
    let i = 0;
    while (i < str.length) {
      const a = str.charCodeAt(i++);
      const b = i < str.length ? str.charCodeAt(i++) : 0;
      const c = i < str.length ? str.charCodeAt(i++) : 0;
      const idx1 = a >> 2;
      const idx2 = ((a & 3) << 4) | (b >> 4);
      const idx3 = b ? (((b & 15) << 2) | (c >> 6)) : 64;
      const idx4 = c ? (c & 63) : 64;
      result += chars[idx1] + chars[idx2] + chars[idx3] + chars[idx4];
    }
    return result;
  }

  const data = $apis.requestInfo(c).data;
  
  if (!data.user_id) {
    throw new BadRequestError("user_id is required");
  }

  // Tentukan harga dan nama berdasarkan plan_type
  let planType = data.plan_type || "monthly"; // default
  let price = 49000;
  let name = "AURA Premium 1 Bulan";

  if (planType === "promo") {
    price = 29000;
    name = "AURA Premium Promo Pengguna Baru (1 Bulan)";
  } else if (planType === "yearly") {
    price = 499000;
    name = "AURA Premium 1 Tahun";
  }

  try {
    // Cari user di database (PocketBase 0.22.x API)
    let user;
    try {
      user = $app.dao().findRecordById("users", data.user_id);
    } catch(e1) {
      console.log("Error finding user '" + data.user_id + "': " + e1);
      throw new BadRequestError("User tidak ditemukan: " + data.user_id);
    }
    
    // Buat Order ID unik: AURA-PREM-[userId]-[planType]-[timestamp]
    const orderId = "AURA-PREM-" + user.id + "-" + planType + "-" + new Date().getTime();
    
    // Siapkan payload untuk Midtrans Snap API
    const payload = {
      "transaction_details": {
        "order_id": orderId,
        "gross_amount": price
      },
      "customer_details": {
        "first_name": user.getString("name") || "Pengguna",
        "email": user.getString("email") || ""
      },
      "item_details": [
        {
          "id": "PREMIUM_" + planType.toUpperCase(),
          "price": price,
          "quantity": 1,
          "name": name
        }
      ]
    };

    // Mode Mock dinonaktifkan karena sudah ada Server Key Production
    // if (MIDTRANS_SERVER_KEY === "...") { ... }

    // Panggil API Midtrans PRODUCTION untuk mendapatkan Snap Token
    const authString = base64Encode(MIDTRANS_SERVER_KEY + ":");
    const res = $http.send({
      url: "https://app.sandbox.midtrans.com/snap/v1/transactions",
      method: "POST",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Basic " + authString
      },
      body: JSON.stringify(payload)
    });

    if (res.statusCode !== 201 && res.statusCode !== 200) {
      console.log("Midtrans Error: " + res.raw);
      throw new BadRequestError("Gagal menghubungi Midtrans");
    }

    // PocketBase 0.22: gunakan JSON.parse(res.raw) bukan res.json()
    console.log("Midtrans Response: " + res.raw);
    const resData = JSON.parse(res.raw);
    
    return c.json(200, {
      "redirect_url": resData.redirect_url,
      "token": resData.token,
      "order_id": orderId
    });

  } catch (err) {
    console.log("Error Checkout: " + err);
    throw new BadRequestError("Terjadi kesalahan saat memproses checkout.");
  }
});


// ==========================================
// 2. ENDPOINT WEBHOOK (Dipanggil oleh Midtrans)
// ==========================================
routerAdd("POST", "/api/midtrans/webhook", (c) => {
  const data = $apis.requestInfo(c).data;
  
  const orderId = data.order_id;
  const transactionStatus = data.transaction_status;
  const fraudStatus = data.fraud_status;
  
  console.log("Menerima Webhook Midtrans - Order: " + orderId + " | Status: " + transactionStatus);

  if (!orderId || !orderId.startsWith("AURA-PREM-")) {
    return c.json(200, { "status": "ignored" });
  }

  // Ekstrak User ID dan Plan dari Order ID (AURA-PREM-userId-planType-timestamp)
  const parts = orderId.split("-");
  if (parts.length < 4) return c.json(200, { "status": "invalid_order_id" });
  
  const userId = parts[2];
  const planType = parts[3];

  // Logika pengecekan status (Success / Settlement)
  if (
    transactionStatus == 'capture' || 
    transactionStatus == 'settlement'
  ) {
    if (fraudStatus == 'challenge') {
      // Masih ditahan, abaikan dulu
      return c.json(200, { "status": "challenged" });
    } else {
      // Pembayaran Sukses! Update User di PocketBase
      try {
        const user = $app.dao().findRecordById("users", userId);
        
        user.set("isPremium", true);
        
        // Tentukan jumlah hari untuk ditambahkan
        let daysToAdd = 30; // default promo/monthly
        if (planType === "yearly") {
          daysToAdd = 365;
        }

        const now = new Date();
        now.setDate(now.getDate() + daysToAdd);
        user.set("premiumExpiredAt", now.toISOString().replace("T", " ").substring(0, 19) + "Z");

        $app.dao().saveRecord(user);
        
        console.log("User " + userId + " berhasil di-upgrade ke Premium!");
      } catch (err) {
        console.log("Gagal update user saat webhook: " + err);
      }
    }
  }

  return c.json(200, { "status": "ok" });
});


// ==========================================
// 3. MOCK PAYMENT PAGE (Hanya untuk Testing jika belum punya akun Midtrans)
// ==========================================
routerAdd("GET", "/api/midtrans/mock-pay", (c) => {
  const orderId = c.queryParam("order_id");
  
  const html = `
  <!DOCTYPE html>
  <html>
  <head>
    <title>Mock Pembayaran Midtrans</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      body { font-family: sans-serif; background: #f4f4f5; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
      .card { background: white; padding: 30px; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); text-align: center; max-width: 350px; width: 100%; }
      h2 { color: #1e1e2c; margin-top: 0; }
      p { color: #666; margin-bottom: 24px; }
      .amount { font-size: 28px; font-weight: bold; color: #f59e0b; margin-bottom: 24px; }
      button { background: #10b981; color: white; border: none; padding: 14px 24px; border-radius: 8px; font-size: 16px; font-weight: bold; cursor: pointer; width: 100%; transition: background 0.3s; }
      button:hover { background: #059669; }
      .note { font-size: 12px; color: #999; margin-top: 20px; }
    </style>
  </head>
  <body>
    <div class="card" id="card">
      <h2>Pilih Metode Pembayaran</h2>
      <p>Order ID:<br><small>${orderId}</small></p>
      <div class="amount">Rp29.000</div>
      <button onclick="pay()">Simulasikan Bayar (QRIS)</button>
      <p class="note">Ini adalah halaman simulasi karena Anda belum memasukkan Midtrans Server Key.</p>
    </div>

    <script>
      function pay() {
        document.querySelector('button').innerText = "Memproses...";
        
        // Kirim Webhook tembakan ke API PocketBase
        fetch('/api/midtrans/webhook', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            "transaction_time": new Date().toISOString(),
            "transaction_status": "settlement",
            "transaction_id": "mock-trx-" + Date.now(),
            "order_id": "${orderId}",
            "gross_amount": "29000.00",
            "fraud_status": "accept"
          })
        }).then(res => {
          document.getElementById('card').innerHTML = "<h2>🎉 Pembayaran Berhasil!</h2><p>Silakan tutup halaman ini dan kembali ke aplikasi.</p><p class='note'>AURA AI mendeteksi pembayaran secara real-time.</p>";
        }).catch(err => {
          alert("Error: " + err);
        });
      }
    </script>
  </body>
  </html>
  `;
  
  return c.html(200, html);
});
