-- Created on first request by the API as well.
CREATE TABLE IF NOT EXISTS billing (
  kind TEXT NOT NULL,
  id TEXT NOT NULL,
  data TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (kind, id)
);
