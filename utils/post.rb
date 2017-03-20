

module Post

  def self.flat(thread_id, offset, limit, ordering)
    result = query %{
        SELECT
          array_to_json(array_agg(t)), count(t)
        FROM (
          SELECT
            U.nickname AS author,
            P.created_at AS created,
            F.slug AS forum,
            P.id AS id,
            P.is_edited AS isEdited,
            P.message AS message,
            P.parent_id AS parent,
            P.thread_id AS thread
          FROM
            Post AS P
            INNER JOIN ForumUser AS U ON (U.id = P.user_id)
            INNER JOIN Thread AS T ON (T.id = P.thread_id)
            INNER JOIN Forum AS F ON (F.id = T.forum_id)
          WHERE
            P.thread_id = $1
          ORDER BY
            P.created_at #{ordering},
            P.id #{ordering}
          LIMIT #{limit.to_i.to_s} OFFSET #{offset.to_i.to_s}
        ) AS t;
        }, [thread_id]

    data = result[0]['array_to_json']
    return '[]', result[0]['count'] if data.nil? || data.length == 0
    return data, result[0]['count']
  end


  def self.tree(thread_id, offset, limit, ordering)
    result = query %{
        SELECT
          array_to_json(array_agg(t)), count(t)
        FROM (
          SELECT
            U.nickname AS author,
            P.created_at AS created,
            F.slug AS forum,
            P.id AS id,
            P.is_edited AS isEdited,
            P.message AS message,
            P.parent_id AS parent,
            P.thread_id AS thread
          FROM
            Post AS P
            INNER JOIN ForumUser AS U ON (U.id = P.user_id)
            INNER JOIN Forum AS F ON (F.id = P.forum_id)
          WHERE
            P.thread_id = $1
          ORDER BY
            P.path #{ordering},
            P.created_at #{ordering},
            P.id #{ordering}
          LIMIT #{limit.to_i.to_s} OFFSET #{offset.to_i.to_s}
        ) AS t
      }, [thread_id]

    data = result[0]['array_to_json']
    return '[]', result[0]['count'] if data.nil? || data.length == 0
    return data, result[0]['count']
  end


  def self.parent_tree(thread_id, offset, limit, ordering)
    result = query %{
        WITH i AS (
          SELECT
            *
          FROM
            Post AS P
          WHERE
            P.parent_id = 0 AND P.thread_id = $1
          ORDER BY
            P.created_at #{ordering},
            P.id #{ordering}
          LIMIT #{limit.to_i.to_s} OFFSET #{offset.to_i.to_s}
        )

        SELECT
          array_to_json(array_agg(t)), (SELECT count(id) FROM i) AS count
        FROM (
          SELECT
            U.nickname AS author,
            P.created_at AS created,
            F.slug AS forum,
            P.id AS id,
            P.is_edited AS isEdited,
            P.message AS message,
            P.parent_id AS parent,
            P.thread_id AS thread
          FROM
            Post AS P
            INNER JOIN ForumUser AS U ON (U.id = P.user_id)
            INNER JOIN Forum AS F ON (F.id = P.forum_id)
          WHERE
            P.path[1] IN (SELECT id FROM i)
          ORDER BY
            P.path #{ordering},
            P.created_at #{ordering},
            P.id #{ordering}
          ) AS t;
      }, [thread_id]

    data = result[0]['array_to_json']
    return '[]', result[0]['count'] if data.nil? || data.length == 0
    return data, result[0]['count']
  end


  def self.info(thread_id, offset, limit, sort, ordering)
    sort = sort.downcase

    if sort == 'flat'
      return self.flat thread_id, offset, limit, ordering
    end

    if sort == 'tree'
      return self.tree thread_id, offset, limit, ordering
    end

    if sort == 'parent_tree'
      return self.parent_tree thread_id, offset, limit, ordering
    end

    nil
  end

end