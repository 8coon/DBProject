require_relative '../db/db'


def drop
  query 'DROP TABLE IF EXISTS Forum;', []
  query 'DROP TABLE IF EXISTS Post;', []
  query 'DROP TABLE IF EXISTS Thread;', []
  query 'DROP TABLE IF EXISTS ThreadVote;', []
  query 'DROP TABLE IF EXISTS ForumUser;', []
  query 'DROP TABLE IF EXISTS ForumMember;', []
end


def create

  query %q{
    CREATE TABLE IF NOT EXISTS Forum (
      id       SERIAL PRIMARY KEY,
      slug     TEXT,
      title    TEXT,
      user_id  INT,
      threads  INT DEFAULT 0,
      posts    INT DEFAULT 0
    );}, []

  query %q{
    CREATE INDEX forum_idx ON Forum (
      id,
      lower(slug),
      user_id
    );}, []

  query %q{
    CREATE TABLE IF NOT EXISTS Thread (
      id              SERIAL PRIMARY KEY,
      user_id         INT,
      created_at      TIMESTAMPTZ(3),
      created_at_str  TEXT,
      forum_id        INT,
      message         TEXT,
      slug            TEXT,
      title           TEXT,
      votes           INT
    );}, []

  query %q{
    CREATE INDEX thread_idx ON Thread (
      id,
      lower(slug),
      user_id,
      forum_id
    );}, []

  query %q{
    CREATE TABLE IF NOT EXISTS ThreadVote (
      thread_id INT,
      user_id   INT UNIQUE,
      voice     SMALLINT
    );}, []

  query %q{
    CREATE INDEX thread_vote_idx ON ThreadVote (
      thread_id,
      user_id
    );}, []

  query %q{
    CREATE TABLE IF NOT EXISTS Post (
      id               SERIAL PRIMARY KEY,
      thread_id        INT,
      user_id          INT,
      created_at       TIMESTAMPTZ(3),
      created_at_str   TEXT,
      is_edited        BOOLEAN,
      message          TEXT,
      parent_id        INT,
      path             INT[],
      forum_id         INT DEFAULT 0,
      insertion_index  INT DEFAULT 0
    );}, []

  query %q{
    CREATE INDEX post_idx ON Post (
      id,
      thread_id,
      user_id,
      parent_id,
      forum_id
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
    CREATE INDEX forum_user_idx ON ForumUser (
      id,
      lower(nickname)
    );}, []

  query %q{
    CREATE TABLE IF NOT EXISTS ForumMember (
      forum_id  INT,
      user_id   INT
    );}, []

  query %q{
    CREATE INDEX forum_member_idx ON ForumMember (
      forum_id,
      user_id
    );}, []


  query %q{
      CREATE OR REPLACE FUNCTION coon_post_insert_check() RETURNS trigger AS
      $func$
        BEGIN
          IF NEW.parent_id > 0 THEN

            CREATE TEMPORARY TABLE parents AS
              SELECT id FROM Post AS P
              WHERE P.id = NEW.parent_id AND P.thread_id = NEW.thread_id
              LIMIT 1;

            IF (SELECT count(*) = 0 FROM parents) THEN
              RAISE EXCEPTION 'No parent post exists!';
            END IF;

            DROP TABLE parents;

          END IF;

          NEW.forum_id = (SELECT forum_id FROM Thread WHERE id = NEW.thread_id);

          UPDATE Forum SET posts = posts + 1
            WHERE id = NEW.forum_id;

          CREATE TEMPORARY TABLE members AS
            SELECT * FROM ForumMember AS M WHERE
              (M.forum_id = NEW.forum_id) AND (M.user_id = NEW.user_id)
            LIMIT 1;

          IF (SELECT count(*) = 0 FROM members) THEN
            INSERT INTO ForumMember
              (forum_id, user_id)
            VALUES
              (NEW.forum_id, NEW.user_id);
          END IF;

          DROP TABLE members;
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


          CREATE TEMP TABLE forum_id AS
            SELECT forum_id AS id FROM Thread AS T WHERE T.id = NEW.thread_id
            LIMIT 1;

          CREATE TEMP TABLE members AS
            SELECT * FROM ForumMember AS M WHERE
              (M.forum_id = (SELECT id FROM forum_id))
              AND (M.user_id = NEW.user_id)
            LIMIT 1;

          IF (SELECT count(*) = 0 FROM members) THEN
            INSERT INTO ForumMember
              (forum_id, user_id)
            VALUES
              ((SELECT id FROM forum_id), NEW.user_id);
          END IF;

          DROP TABLE members;
          DROP TABLE forum_id;
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
      CREATE OR REPLACE FUNCTION coon_forum_thread_count() RETURNS trigger AS
      $func$
        BEGIN
          UPDATE Forum SET threads = threads + 1
            WHERE id = NEW.forum_id;

          CREATE TEMPORARY TABLE members AS
            SELECT * FROM ForumMember AS M WHERE
              (M.forum_id = NEW.forum_id) AND (M.user_id = NEW.user_id)
            LIMIT 1;

          IF (SELECT count(*) = 0 FROM members) THEN
            INSERT INTO ForumMember
              (forum_id, user_id)
            VALUES
              (NEW.forum_id, NEW.user_id);
          END IF;

          DROP TABLE members;
          RETURN NEW;
        END
      $func$
      LANGUAGE plpgsql;
    }, []

  query %q{
      DROP TRIGGER IF EXISTS coon_thread_count ON Thread;
    }, []

  query %q{
      CREATE TRIGGER coon_thread_count AFTER INSERT
        ON Thread FOR EACH ROW EXECUTE PROCEDURE coon_forum_thread_count();
    }, []


  query %q{
      CREATE OR REPLACE FUNCTION coon_post_is_edited() RETURNS trigger AS
      $func$
        BEGIN
          IF NEW.message <> OLD.message THEN
            NEW.is_edited = TRUE;
          END IF;

          RETURN NEW;
        END
      $func$
      LANGUAGE plpgsql;
    }, []

  query %q{
      DROP TRIGGER IF EXISTS coon_edited_check ON Post;
    }, []

  query %q{
      CREATE TRIGGER coon_edited_check BEFORE UPDATE
        ON Post FOR EACH ROW EXECUTE PROCEDURE coon_post_is_edited();
    }, []

end


