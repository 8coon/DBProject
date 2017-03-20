require 'sinatra'
require_relative '../../db/db'
require_relative '../../migrations/create_db_schema'


post '/api/service/clear' do
  drop
  create
end


get '/api/service/query_stats' do
  body time_stats.join "\n"
end


get '/api/service/status' do
  result = query %q{
      SELECT
        (SELECT count(*) FROM Forum LIMIT 1) AS forum,
        (SELECT count(*) FROM Post LIMIT 1) AS post,
        (SELECT count(*) FROM Thread LIMIT 1) AS thread,
        (SELECT count(*) FROM ForumUser LIMIT 1) AS "user"
    }, []

  data = JSON.fast_unparse({
    forum: result[0]['forum'].to_i,
    post: result[0]['post'].to_i,
    thread: result[0]['thread'].to_i,
    user: result[0]['user'].to_i,
  })

  body data
end
