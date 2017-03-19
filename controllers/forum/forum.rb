require 'sinatra'
require_relative '../../db/db'
require_relative '../../utils/user'
require_relative '../../utils/forum'


post '/api/forum/create' do
  data = JSON.parse request.body.read
  user_id = User.exists? data['user']
  halt 404 unless user_id

  if Forum.exists_with_title? data['slug'], data['title']
    result = query %q{
      SELECT row_to_json(t) FROM (
        SELECT F.slug AS slug, F.title AS title, U.nickname AS "user"
        FROM Forum as F INNER JOIN ForumUser as U ON (U.id = F.user_id)
        WHERE (lower(F.slug) = $1 OR lower(F.title) = $2))
        AS t;
      }, [data['slug'].downcase, data['title'].downcase]

    body result[0]['row_to_json']
    halt 409
  end

  query %q{
    INSERT INTO Forum
      (slug, title, user_id)
    VALUES
      ($1, $2, $3);
    }, [data['slug'], data['title'], user_id]

  result = query %q{
      SELECT nickname FROM ForumUser WHERE id = $1 LIMIT 1;
    }, [user_id]

  data['user'] = result[0]['nickname']
  status 201
  body JSON.fast_unparse data
end


get '/api/forum/:slug/details' do
  slug = params['slug']
  halt 404 unless Forum.exists? slug

  result = query %q{
    SELECT row_to_json(t) FROM (
      SELECT F.slug AS slug, F.title AS title, U.nickname AS "user"
      FROM Forum as F INNER JOIN ForumUser as U ON (U.id = F.user_id)
      WHERE (lower(F.slug) = $1) LIMIT 1)
      AS t;
    }, [slug.downcase]
  body result[0]['row_to_json']
end