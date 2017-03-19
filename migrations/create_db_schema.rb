require_relative '../db/db'


def create

  query %q{
    CREATE TABLE IF NOT EXISTS Forum (
      id       SERIAL PRIMARY KEY,
      slug     TEXT,
      title    TEXT,
      user_id  INT
    );}, []

  query %q{
    CREATE TABLE IF NOT EXISTS Thread (
      id          SERIAL PRIMARY KEY,
      user_id     INT,
      created_at  INT,
      forum_id    INT,
      message     TEXT,
      slug        TEXT,
      title       TEXT
    );}, []

  query %q{
    CREATE TABLE IF NOT EXISTS ThreadVote (
      thread_id INT,
      user_id   INT,
      vote      INT
    );}, []

  query %q{
    CREATE TABLE IF NOT EXISTS Post (
      id          SERIAL PRIMARY KEY,
      thread_id   INT,
      user_id     INT,
      created_at  INT,
      is_edited   BOOLEAN,
      message     TEXT,
      parent_id   INT
    );}, []

  query %q{
    CREATE TABLE IF NOT EXISTS ForumUser (
      id        SERIAL PRIMARY KEY,
      about     TEXT,
      email     TEXT,
      fullname  TEXT,
      nickname  TEXT
    );}, []

end


