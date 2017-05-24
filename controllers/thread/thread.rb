require 'sinatra'
require_relative '../../db/db'
require_relative '../../utils/user'
require_relative '../../utils/forum'
require_relative '../../utils/thread'


post '/api/forum/:slug/create' do
  data = JSON.parse request.body.read
  slug = params['slug']

  user_id = User.exists? data['author']
  halt 404 unless user_id

  forum_id = Forum.exists? slug
  halt 404 unless forum_id

  thread_id = ForumThread.exists? data['slug']
  if thread_id
    body ForumThread.info thread_id
    halt 409
  end

  result = query %q{
    INSERT INTO Thread
      (user_id, created_at, forum_id, message, slug, title, votes, created_at_str)
    VALUES
      ($1, $2, $3, $4, $5, $6, 0, $7)
    RETURNING id;
    }, [user_id, data['created'] || Time.now, forum_id, data['message'],
        data['slug'], data['title'], data['created'] || ForumThread.now]

  status 201
  body ForumThread.info result[0]['id']
end


get '/api/forum/:slug/threads' do
  slug = params['slug']

  forum_id = Forum.exists? slug
  halt 404 unless forum_id

  sorting = ForumThread.sorting params[:desc]
  since = params[:since]
  limit = params[:limit]
  cmp = '>='
  cmp = '<=' if sorting == 'DESC'

  where = 'F.id = $1'
  where_args = [forum_id]

  if since
    where = "F.id = $1 AND T.created_at #{cmp} $2"
    where_args.push since
  end

  threads = ForumThread.threads where, where_args, "t.created_at #{sorting}",
                                true, limit

  if threads.ntuples == 0 || threads[0]['array_to_json'].to_s.length == 0
    body '[]'
    return
  end

  body threads[0]['array_to_json']
end


post '/api/thread/:slug_or_id/vote' do
  data = JSON.parse request.body.read
  voice = -1
  voice = 1 if data['voice'].to_s == '1'

  user_id = User.exists? data['nickname']
  halt 404 unless user_id

  thread_id = ForumThread.exists? params['slug_or_id']
  halt 404 unless thread_id


  transaction do |conn|
    result = conn.query %q{
        SELECT
          voice
        FROM
          ThreadVote
        WHERE
          user_id = $1 AND thread_id = $2;
      }, [user_id, thread_id]

    voice_mod = voice

    if result.ntuples != 0
      voice_mod = voice - result[0]['voice'].to_i

      conn.query %q{
          UPDATE
            ThreadVote
          SET
            voice = $3
          WHERE
            thread_id = $1 AND user_id = $2;
        }, [thread_id, user_id, voice]
    else
      conn.query %q{
          INSERT INTO ThreadVote
            (thread_id, user_id, voice)
          VALUES
            ($1, $2, $3);
        }, [thread_id, user_id, voice]
    end


    result = conn.query %q{
      SELECT row_to_json(t) FROM (
        SELECT
          U.nickname AS author,
          T.created_at AS created,
          F.slug AS forum,
          T.id AS id,
          T.message AS message,
          T.title AS title,
          T.slug AS slug,
          T.votes AS votes,
          F.id AS forum_id
        FROM
          Thread AS T
          INNER JOIN ForumUser AS U ON (T.user_id = U.id)
          INNER JOIN Forum AS F ON (T.forum_id = F.id)
        WHERE
          T.id = $1
      ) AS t;
      }, [thread_id]

    result = JSON.parse result[0]['row_to_json']

    user = conn.query %q{
        SELECT user_id FROM ForumMember WHERE forum_id = $1;
      }, [result['forum_id']]

    if user.ntuples == 0
      conn.query %q{
        INSERT INTO ForumMember
          (forum_id, user_id)
        VALUES
          ($1, $2)
      }, [result['forum_id'], user_id]
    end

    conn.query 'UPDATE Thread SET votes = votes + $2 WHERE id = $1;',
               [thread_id, voice_mod]

    result['votes'] = result['votes'].to_i + voice_mod
    body(JSON.pretty_generate result)
  end
end


get '/api/thread/:slug_or_id/details' do
  thread_id = ForumThread.exists? params['slug_or_id']
  halt 404 unless thread_id

  body ForumThread.info thread_id
end


post '/api/thread/:slug_or_id/details' do
  thread_id = ForumThread.exists? params['slug_or_id']
  halt 404 unless thread_id

  data = JSON.parse request.body.read

  keys = []
  args = []
  values = []

  data['id'] = nil
  data['slug'] = nil
  data['votes'] = nil

  data.each do |key, value|
    unless value.nil?
      keys.push key
      args.push '$' + (args.length + 1).to_s
      values.push value
    end
  end

  if values.length > 0
    values.push thread_id

    query %{
        UPDATE Thread SET
          (#{keys.join ','}) = (#{args.join ','})
        WHERE (id = $#{args.length + 1});
      }, values
  end

  body ForumThread.info thread_id
end
