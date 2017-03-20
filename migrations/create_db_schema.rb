require_relative '../db/db'


def drop
  query 'DROP TABLE IF EXISTS Forum;', []
  query 'DROP TABLE IF EXISTS Post;', []
  query 'DROP TABLE IF EXISTS Thread;', []
  query 'DROP TABLE IF EXISTS ThreadVote;', []
  query 'DROP TABLE IF EXISTS ForumUser;', []
end


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
      title       TEXT,
      votes       INT
    );}, []

  query %q{
    CREATE TABLE IF NOT EXISTS ThreadVote (
      thread_id INT,
      user_id   INT UNIQUE,
      voice     SMALLINT
    );}, []

  query %q{
    CREATE TABLE IF NOT EXISTS Post (
      id               SERIAL PRIMARY KEY,
      thread_id        INT,
      user_id          INT,
      created_at       TIMESTAMPTZ,
      is_edited        BOOLEAN,
      message          TEXT,
      parent_id        INT,
      path             INT[]
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
          IF NEW.parent_id > 0 THEN

            CREATE TEMPORARY TABLE parents AS
              SELECT id FROM Post AS P WHERE P.id = NEW.parent_id LIMIT 1;

            IF (SELECT count(*) = 0 FROM parents) THEN
              RAISE EXCEPTION 'No parent post exists!';
            END IF;

            DROP TABLE parents;

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


  query %q{
      CREATE OR REPLACE FUNCTION coon_thread_votes_check() RETURNS trigger AS
      $func$
        BEGIN

          IF TG_OP = 'INSERT' THEN
            UPDATE Thread SET
              votes = votes + NEW.voice
            WHERE NEW.thread_id = id;
            RETURN NULL;
          END IF;

          IF OLD.voice = NEW.voice THEN
            RETURN NULL;
          END IF;

          UPDATE Thread SET
            votes = votes + CASE WHEN NEW.voice = -1 THEN -2 ELSE 2 END
          WHERE NEW.thread_id = id;
          RETURN NULL;
        END
      $func$
      LANGUAGE plpgsql;
    }, []

  query %q{
      DROP TRIGGER IF EXISTS coon_votes_check ON ThreadVote;
    }, []

  query %q{
      CREATE TRIGGER coon_votes_check AFTER INSERT OR UPDATE
        ON ThreadVote FOR EACH ROW EXECUTE PROCEDURE coon_thread_votes_check();
    }, []


  query %q{
    }, []

end


