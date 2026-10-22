-- user_id is the Firebase uid (the ID token's sub). There is no users table.
-- UNIQUE (id, user_id) is redundant as a key (id alone is unique), but SQLite
-- needs it as the parent key of the pages' composite foreign key.
CREATE TABLE notebooks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT,
  UNIQUE (user_id, name),
  UNIQUE (id, user_id)
);

-- A page's user_id must be its notebook's: the composite foreign key makes a
-- page in someone else's notebook impossible. No ON DELETE: a notebook with
-- pages can't be deleted (the API answers 409 before getting there).
CREATE TABLE pages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  notebook_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT '',
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (notebook_id, user_id) REFERENCES notebooks (id, user_id)
);
-- The page list: WHERE notebook_id = ? ORDER BY updated_at DESC, id DESC.
CREATE INDEX index_pages_on_notebook_id_and_updated_at ON pages (notebook_id, updated_at, id);
