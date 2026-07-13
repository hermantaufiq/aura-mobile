migrate((db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("payments");

  // Allow users to create their own payment records.
  collection.createRule = "@request.auth.id != '' && @request.auth.id = user.id";
  
  // Allow admins to view, list, and update all payment records.
  collection.listRule = "@request.auth.id != '' && (@request.auth.id = user.id || @request.auth.role = 'admin')";
  collection.viewRule = "@request.auth.id != '' && (@request.auth.id = user.id || @request.auth.role = 'admin')";
  collection.updateRule = "@request.auth.role = 'admin'";

  return dao.saveCollection(collection);
}, (db) => {
  const dao = new Dao(db);
  const collection = dao.findCollectionByNameOrId("payments");

  collection.createRule = null;
  collection.listRule = "@request.auth.id != '' && @request.auth.id = user.id";
  collection.viewRule = "@request.auth.id != '' && @request.auth.id = user.id";
  collection.updateRule = null;

  return dao.saveCollection(collection);
});
