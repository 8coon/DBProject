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
      created_at  TIMESTAMPTZ,
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
      created_at  TIMESTAMPTZ,
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


  query %q{
      CREATE OR REPLACE FUNCTION coon_post_insert_check() RETURNS trigger AS
      $func$
        BEGIN
          IF ((NEW.parent_id > 0) AND
              (SELECT count(*) FROM Post AS P WHERE P.id = NEW.parent_id) > 0) THEN
            RAISE EXCEPTION 'No parent post exists!';
          END IF;
          RETURN NEW;
        END
      $func$
      LANGUAGE plpgsql;
    }, []

  query %q{
      DROP TRIGGER IF EXISTS coon_post_check ON Post;
    }, []

  query %q{
      CREATE TRIGGER coon_post_check BEFORE INSERT
        ON Post FOR EACH ROW EXECUTE PROCEDURE coon_post_insert_check();
    }, []

end


