/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = $app.dao();
  const adminEmail = 'admin@aura.ai';
  
  // 1. Create default admin user if not exists
  const usersCollection = dao.findCollectionByNameOrId('users');
  try {
    dao.findFirstRecordByData('users', 'email', adminEmail);
    // Already exists
  } catch (e) {
    // Does not exist, create
    const record = new Record(usersCollection);
    record.set('email', adminEmail);
    record.set('username', 'admin_super');
    record.set('emailVisibility', true);
    record.set('password', 'admin1234');
    record.set('passwordConfirm', 'admin1234');
    record.set('name', 'Super Admin');
    record.set('role', 'admin');
    record.set('verified', true);
    dao.saveRecord(record);
  }

  // 2. Update listRule for collections
  const collectionsToUpdate = ['users', 'tasks', 'finances', 'notifications'];
  for (const name of collectionsToUpdate) {
    try {
      const collection = dao.findCollectionByNameOrId(name);
      
      if (name === 'users') {
        collection.listRule = "id = @request.auth.id || @request.auth.role = 'admin'";
      } else {
        collection.listRule = "user = @request.auth.id || @request.auth.role = 'admin'";
      }
      dao.saveCollection(collection);
    } catch (err) {
      console.log('Error updating ' + name + ': ' + err);
    }
  }
}, (db) => {
  // Revert logic
});

