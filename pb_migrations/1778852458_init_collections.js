/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db);

  // --- Tasks ---
  const tasks = new Collection({
    "name": "tasks",
    "type": "base",
    "system": false,
    "schema": [
      { "name": "user", "type": "text", "required": true },
      { "name": "title", "type": "text", "required": true },
      { "name": "description", "type": "text" },
      { "name": "deadline", "type": "date" },
      { "name": "priority", "type": "text" },
      { "name": "status", "type": "text" }
    ],
    "listRule": "",
    "viewRule": "",
    "createRule": "",
    "updateRule": "",
    "deleteRule": ""
  });

  // --- Finances ---
  const finances = new Collection({
    "name": "finances",
    "type": "base",
    "system": false,
    "schema": [
      { "name": "user", "type": "text", "required": true },
      { "name": "type", "type": "text", "required": true },
      { "name": "category", "type": "text", "required": true },
      { "name": "amount", "type": "number", "required": true },
      { "name": "note", "type": "text" },
      { "name": "date", "type": "date", "required": true }
    ],
    "listRule": "",
    "viewRule": "",
    "createRule": "",
    "updateRule": "",
    "deleteRule": ""
  });

  // --- AI Chats ---
  const ai_chats = new Collection({
    "name": "ai_chats",
    "type": "base",
    "system": false,
    "schema": [
      { "name": "user", "type": "text", "required": true },
      { "name": "message", "type": "text", "required": true },
      { "name": "response", "type": "text", "required": true }
    ],
    "listRule": "",
    "viewRule": "",
    "createRule": "",
    "updateRule": "",
    "deleteRule": ""
  });

  dao.saveCollection(tasks);
  dao.saveCollection(finances);
  dao.saveCollection(ai_chats);

  return null;
}, (db) => {
  const dao = new Dao(db);

  try { const c1 = dao.findCollectionByNameOrId("tasks"); dao.deleteCollection(c1); } catch(e) {}
  try { const c2 = dao.findCollectionByNameOrId("finances"); dao.deleteCollection(c2); } catch(e) {}
  try { const c3 = dao.findCollectionByNameOrId("ai_chats"); dao.deleteCollection(c3); } catch(e) {}

  return null;
})
