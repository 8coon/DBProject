require 'sinatra'
require_relative '../../db/db'
require_relative '../../utils/user'
require_relative '../../utils/forum'


post '/api/forum/create' do
  data = JSON.parse request.body.read
  user_id = User.exists? data['user']
  halt 404 unless user_id

  if Forum.exists_with_title? data['slug'], data['title']
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