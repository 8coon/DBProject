require 'sinatra'
require_relative '../../db/db'
require_relative '../../utils/user'
require_relative '../../utils/forum'
require_relative '../../utils/thread'


post '/api/forum/create' do
  data = JSON.parse request.body.read
  user_id = User.exists? data['user']
  halt 404 unless user_id

  if Forum.exists? data['slug']
    info = Forum.info data['slug']
    body info
    halt 409
  end

  query %q{
    INSERT INTO Forum
      (slug, title, user_id)
    VALUES
      ($1, $2, $3);
    }, [data['slug'], data['title'], user_id]

  data['user'] = User.by_id user_id
  status 201
  body JSON.fast_unparse data
end


get '/api/forum/:slug/details' do
  slug = params['slug']
  halt 404 unless Forum.exists? slug
  body Forum.info slug
end


get '/api/forum/:slug/users' do
  slug = params['slug']
  forum_id = Forum.exists? slug
  halt 404 unless forum_id

  limit = params[:limit] || 100
  ordering = ForumThread.sorting params[:desc]
  since = params[:since] || ''
  cmp = '>'
  cmp = '<' if ordering == 'DESC'

  params = [forum_id]
  params.push since.downcase if since.length > 0

  result = query %{
    SELECT array_to_json(array_agg(t)) FROM (
      SELECT
        U.about AS about,
        U.email AS email,
        U.fullname AS fullname,
        U.nickname AS nickname
      FROM
        ForumMember AS M
        INNER JOIN ForumUser AS U ON (U.id = M.user_id)
      WHERE
        M.forum_id = $1
        #{"AND lower(U.nickname) #{cmp} $2" if since.length > 0}
      ORDER BY
        lower(U.nickname) #{ordering}
      LIMIT #{limit.to_s.to_i}
      ) AS t
    }, params

  data = result[0]['array_to_json'] || ''
  data = '[]' if data.length == 0
  body data
end
