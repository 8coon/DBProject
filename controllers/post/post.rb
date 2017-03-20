require 'sinatra'
require 'sinatra'
require_relative '../../db/db'
require_relative '../../utils/user'
require_relative '../../utils/forum'
require_relative '../../utils/thread'
require_relative '../../utils/post'


post '/api/thread/:slug_or_id/create' do
  data = JSON.parse request.body.read
  thread_id = ForumThread.exists? params['slug_or_id']
  halt 404 unless thread_id

  queries = []
  values = []

  data.each do |post_data|
    i = values.length

    # (thread_id, user_id, created_at, is_edited, message, parent_id)

    queries.push "
      SELECT
        $#{i+1}::INT          as thread_id,
        U.id::INT             as user_id,
        $#{i+3}::TIMESTAMPTZ  as created_at,
        $#{i+6}::BOOLEAN      as is_edited,
        $#{i+4}::TEXT         as message,
        $#{i+5}::INT          as parent_id,
        $#{i+7}::INT          as insertion_index
      FROM
        ForumUser AS U
      WHERE
        (lower(U.nickname) = lower($#{i+2}::TEXT))
      "

    values.concat [thread_id.to_i,
                   post_data['author'],
                   post_data['created'] || Time.now,
                   post_data['message'],
                   post_data['parent'] || 0,
                   post_data['isEdited'],
                   queries.length
                  ]
  end

  begin
    result = query %{
      WITH i AS (
        SELECT
          *
        FROM
          (#{queries.join "\n UNION ALL \n"}) AS i0
        ORDER BY insertion_index ASC
      ), k AS (
        SELECT coalesce(max(id), 0) FROM Post
      ), j AS (
        INSERT INTO Post AS P
          (thread_id, user_id, created_at, is_edited, message, parent_id,
           path)
        SELECT
          thread_id, user_id, created_at, is_edited, message, parent_id,
            (SELECT P2.path FROM Post AS P2 WHERE P2.id = i.parent_id) ||
            ((row_number() OVER ()) + (SELECT * FROM k))::INT
        FROM i
      )

      SELECT
        array_to_json(array_agg(t2))
      FROM (
          SELECT
            U.nickname AS author,
            i.created_at AS created,
            F.slug AS forum,
            (row_number() OVER ()) + (SELECT * FROM k) AS id,
            i.is_edited AS isEdited,
            i.message AS message,
            i.parent_id AS parent,
            i.thread_id AS thread
          FROM
            i
            INNER JOIN ForumUser AS U ON (U.id = i.user_id)
            INNER JOIN Thread AS T ON (T.id = i.thread_id)
            INNER JOIN Forum AS F ON (F.id = T.forum_id)
          ORDER BY i.insertion_index ASC
      ) AS t2;
    }, values
  rescue PG::Error
    halt 409
  end

  status 201
  body result[0]['array_to_json']
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



