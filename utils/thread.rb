require_relative '../db/db'
require_relative '../utils/forum'


module ForumThread

  def self.sorting(desc)
    return 'DESC' if desc.to_s.downcase == 'true'
    'ASC'
  end


  def self.exists?(slug_or_id)
    return false if slug_or_id.nil?

    param = 'id'
    param = 'lower(slug)' if Forum.slug? slug_or_id

    result = query %{
      SELECT id FROM Thread WHERE
      (#{param} = $1) LIMIT 1;
      }, [slug_or_id.to_s.downcase]

    return false if result.ntuples == 0
    return result[0]['id']
  end


  def self.threads(where, where_args, order_by = nil, array = nil, limit = nil)
    order_by = "ORDER BY #{order_by}" if order_by
    json_agg = 'row_to_json(t)'
    json_agg = 'array_to_json(array_agg(t))' if array
    limit = "LIMIT #{limit.to_s}" if limit

    result = query %{
      SELECT #{json_agg} FROM (
        SELECT
          U.nickname AS author,
          T.created_at AS created,
          F.slug AS forum,
          T.id AS id,
          T.message AS message,
          T.title AS title,
          T.slug AS slug,
          T.votes AS votes
        FROM
          Thread AS T
          INNER JOIN ForumUser AS U ON (T.user_id = U.id)
          INNER JOIN Forum AS F ON (T.forum_id = F.id)
        WHERE
          #{where}
        #{order_by || ''}
        #{limit || ''}
      ) AS t
      }, where_args || []

    return result
  end


  def self.info(slug_or_id)
    param = 'T.id'
    param = 'lower(T.slug)' if Forum.slug? slug_or_id

    result = self.threads "#{param} = $1", [slug_or_id.to_s.downcase]
    return result[0]['row_to_json']
  end

end