/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = $app.dao();
  
  try {
    // Cari admin lama (admin@aura.ai)
    const record = dao.findFirstRecordByData('users', 'email', 'admin@aura.ai');
    
    // Update email dan password
    record.set('email', 'aura@gmail.com');
    record.set('password', 'aura123?');
    record.set('passwordConfirm', 'aura123?');
    
    dao.saveRecord(record);
    console.log("âœ… Berhasil update kredensial Admin");
  } catch (e) {
    console.log("Admin admin@aura.ai tidak ditemukan atau sudah diganti.");
  }
}, (db) => {
  // Revert
  const dao = $app.dao();
  try {
    const record = dao.findFirstRecordByData('users', 'email', 'aura@gmail.com');
    record.set('email', 'admin@aura.ai');
    record.set('password', 'admin1234');
    record.set('passwordConfirm', 'admin1234');
    dao.saveRecord(record);
  } catch (e) {}
});

