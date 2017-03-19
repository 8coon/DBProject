require 'sinatra'
require_relative '../../db/db'
require_relative '../../utils/user'


post '/api/user/:nickname/create' do
  data = JSON.parse request.body.read
  nickname = params['nickname']

  if User.exists_with_email? nickname, data['email']
    users = query %q{
      SELECT array_to_json(array_agg(row_to_json(t))) FROM (
        SELECT id, about, email, fullname, nickname
        FROM ForumUser as U WHERE (lower(U.nickname) = $1 OR lower(U.email) = $2))
        AS t;
      }, [nickname.downcase, data['email'].downcase]

    body users[0]['array_to_json']
    halt 409
  end

  query %q{
    INSERT INTO ForumUser
      (about, email, fullname, nickname)
    VALUES
      ($1, $2, $3, $4);
    }, [data['about'], data['email'], data['fullname'], nickname]

  status 201
  data['nickname'] = nickname
  body JSON.fast_unparse data
end


get '/api/user/:nickname/profile' do
  nickname = params['nickname']
  halt 404 unless User.exists? nickname

  data = query %q{
    SELECT row_to_json(U) FROM ForumUser as U WHERE (lower(U.nickname) = $1) LIMIT 1;
    }, [nickname.downcase]
  body data[0]['row_to_json']
end


post '/api/user/:nickname/profile' do
  data = JSON.parse request.body.read
  nickname = params['nickname']

  id = User.exists? nickname
  halt 404 unless id

  unless data['nickname'].nil?
    halt 409 if User.exists? data['nickname']
  end

  unless data['email'].nil?
    halt 409 if User.exists_email? data['email']
  end

  keys = []
  args = []
  values = []
  data['id'] = nil

  data.each do |key, value|
    unless value.nil?
      keys.push key
      args.push '$' + (args.length + 1).to_s
      values.push value
    end
  end

  if values.length > 0
    values.push id

    query %{
        UPDATE ForumUser SET
          (#{keys.join ','}) = (#{args.join ','})
        WHERE (id = $#{args.length + 1});
      }, values
  end

  data = query %q{
    SELECT row_to_json(U) FROM ForumUser as U WHERE (U.nickname = $1) LIMIT 1;
    }, [nickname]
  body data[0]['row_to_json']
end
