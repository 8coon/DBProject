require_relative '../db/db'


def create

  query %q{
    CREATE TABLE IF NOT EXISTS Forum (
      id       INT,
      slug     TEXT,
      title    TEXT,
      user_id  INT
    );}, []

  query %q{
    CREATE TABLE IF NOT EXISTS Thread (
      id          INT,
      user_id     INT,
      created_at  INT,
      forum_id    INT,
      message     TEXT,
      slug        TEXT,
      title       TEXT
    );}, []

  query %q{
    CREATE TABLE IF NOT EXISTS ThreadVotes (
      thread_id INT,
      user_id   INT,
      vote      INT
    );}, []



end


