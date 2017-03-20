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
      (user_id, created_at, forum_id, message, slug, title, votes)
    VALUES
      ($1, $2, $3, $4, $5, $6, 0)
    RETURNING id;
    }, [user_id, data['created'] || Time.now, forum_id, data['message'],
        data['slug'], data['title']]

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

  query %q{
      INSERT INTO ThreadVote
        (thread_id, user_id, voice)
      VALUES
        ($1, $2, $3)
      ON CONFLICT(user_id) DO
        UPDATE SET voice = $3;
    }, [thread_id, user_id, voice]

  body ForumThread.info thread_id
end


get '/api/thread/:slug_or_id/details' do
  thread_id = ForumThread.exists? params['slug_or_id']
  halt 404 unless thread_id

  body ForumThread.info thread_id
end
