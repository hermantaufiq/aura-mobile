/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = $app.dao();
  const collection = dao.findCollectionByNameOrId("_pb_users_auth_");

  collection.updateRule = ""; // Allow public update for OTP verification (dev mode)

  return dao.saveCollection(collection);
}, (db) => {
  const dao = $app.dao();
  const collection = dao.findCollectionByNameOrId("_pb_users_auth_");

  collection.updateRule = "id = @request.auth.id";

  return dao.saveCollection(collection);
})

