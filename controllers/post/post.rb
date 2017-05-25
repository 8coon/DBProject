require 'sinatra'
require 'sinatra'
require_relative '../../db/db'
require_relative '../../utils/user'
require_relative '../../utils/forum'
require_relative '../../utils/thread'
require_relative '../../utils/post'


post '/api/thread/:slug_or_id/create' do
  data = JSON.parse request.body.read

  thread_info = ForumThread.exists_with_forum params['slug_or_id']
  halt 404 unless thread_info

  thread_id = thread_info[:id]
  forum_name = thread_info[:forum]

  created = (data[0] || {})['created'] || ForumThread.now
  queries = []

  data.each do |post_data|
    post_data['created'] = ForumThread.fm_time(Time.parse(created))

    user_id = User.exists? post_data['author']
    halt 404 unless user_id

    queries.push %{
          (
            #{thread_id},
            #{user_id},
            '#{post_data['created']}',
            #{post_data['isEdited'].to_s.downcase == 'true'},
            '#{post_data['message']}',
            #{post_data['parent'] || 0},
            '#{post_data['created']}'
          )
      }
  end

  insert_query = %{
      INSERT INTO Post AS P (
          thread_id, user_id, created_at, is_edited, message, parent_id,
          created_at_str
      ) VALUES #{queries.join(', ')}
      RETURNING
        id
      ;}

  begin
    ids = query_unprepared insert_query

    halt 404 if ids.ntuples != data.length

    data.each_with_index do |post_data, index|
      post_data['id'] = ids[index]['id'].to_i
      post_data['thread'] = thread_id.to_i
      post_data['forum'] = forum_name
    end
  rescue PG::Error
    halt 409
  end

  status 201
  body(JSON.pretty_generate data)
end


get '/api/thread/:slug_or_id/posts' do
  thread_id = ForumThread.exists? params['slug_or_id']
  halt 404 unless thread_id

  limit = params[:limit].to_i || 100
  offset = params[:marker].to_i || 0
  sort = params[:sort] || 'flat'
  ordering = ForumThread.sorting params[:desc]

  data, count = Post.info thread_id, offset, limit, sort, ordering

  body %{
      \{
        "marker": "#{offset + count.to_i}",
        "posts": #{data}
      \}
    }
end


def format_date(date)
  date
end


def format_date2(date)
  p date
  date = date.sub(' ', 'T')
  floats = date[/\.\d\d\d\+/]

  unless floats
    floats = date[/\.\d\d\+/]

    if floats
      floats = floats.sub('+', '')
      date = date.sub(floats, floats + '0')
    else
      floats = date[/\.\d\+/]

      if floats
        floats = floats.sub('+', '')
        date = date.sub(floats, floats + '00')
      else
        date = date.sub('+', '.000+')
      end
    end
  end

  date = date + ':00'
  p date
  date
end


get '/api/post/:id/details' do
  post_id = params['id'].to_i
  related_arr = (params[:related] || '').sub(' ', '').split ','
  related = {}
  related_arr.each { |x| related[x] = true }

  result = query %q{
    SELECT
      *,
      T.slug AS thread_slug,
      F.slug AS forum_slug,
      T.title AS thread_title,
      F.title AS forum_title,
      FU.nickname AS forum_author,
      TU.nickname AS thread_author,
      T.id AS thread_id,
      T.created_at_str AS thread_created,
      T.message AS thread_message,
      P.id AS post_id,
      P.created_at_str AS post_created,
      P.message AS post_message,
      U.nickname AS post_author_nickname,
      U.fullname AS post_author_fullname,
      U.about AS post_author_about,
      U.email AS post_author_email
    FROM
      Post AS P
      INNER JOIN ForumUser AS U ON (U.id = P.user_id)
      INNER JOIN Thread AS T ON (T.id = P.thread_id)
      INNER JOIN Forum AS F ON (F.id = P.forum_id)
      INNER JOIN ForumUser AS FU ON (FU.id = F.user_id)
      INNER JOIN ForumUser AS TU ON (TU.id = T.user_id)
    WHERE
      P.id = $1
    }, [post_id]

  halt 404 if result.ntuples == 0
  result = result[0]

  author = {
      about:    result['post_author_about'],
      email:    result['post_author_email'],
      fullname: result['post_author_fullname'],
      nickname: result['post_author_nickname'],
  }

  forum = {
      posts:    result['posts'].to_i,
      slug:     result['forum_slug'],
      threads:  result['threads'].to_i,
      title:    result['forum_title'],
      user:     result['forum_author'],
  }

  post = {
      author:   result['post_author_nickname'],
      created:  format_date(result['post_created']),
      forum:    result['forum_slug'],
      id:       result['post_id'].to_i,
      isEdited: result['is_edited'] == 't',
      message:  result['post_message'],
      thread:   result['thread_id'].to_i,
  }

  p post

  thread = {
      author:   result['thread_author'],
      created:  format_date(result['thread_created']),
      forum:    result['forum_slug'],
      id:       result['thread_id'].to_i,
      message:  result['thread_message'],
      slug:     result['thread_slug'],
      title:    result['thread_title']
  }

  data = {
      post: post,
  }

  data[:author] = author if related['user']
  data[:thread] = thread if related['thread']
  data[:forum] = forum if related['forum']

  body JSON.pretty_generate data
end


post '/api/post/:id/details' do
  data = JSON.parse request.body.read
  post_id = params['id'].to_i

  keys = []
  args = []
  values = []

  data['id'] = nil
  data['user_id'] = nil
  # data['is_edited'] = true if data['message']

  data.each do |key, value|
    unless value.nil?
      keys.push key
      args.push '$' + (args.length + 1).to_s
      values.push value
    end
  end

  if values.length > 0
    values.push post_id.to_i

    query %{
        UPDATE Post SET
          (#{keys.join ','}) = (#{args.join ','})
        WHERE (id = $#{args.length + 1});
      }, values
  end

  result = query %q{
    SELECT row_to_json(t) FROM (
      SELECT
        U.nickname AS author,
        P.created_at AS created,
        F.slug AS forum,
        P.id AS id,
        P.is_edited AS "isEdited",
        P.message AS message,
        P.parent_id AS parent,
        P.thread_id AS thread
      FROM
        Post AS P
        INNER JOIN ForumUser AS U ON (U.id = P.user_id)
        INNER JOIN Forum AS F ON (F.id = P.forum_id)
      WHERE
        P.id = $1
      ) AS t;
    }, [post_id.to_i]

  halt 404 if result.ntuples == 0
  body result[0]['row_to_json']
end



