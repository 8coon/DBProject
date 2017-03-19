require_relative '../db/db'


module Forum

  def self.is_i?(str)
    /\A[-+]?\d+\z/ === str.to_s
  end

  def self.slug?(str)
    !(Forum.is_i? str)
  end


  def self.exists?(slug_or_id)
    field = 'id'
    arg = '$1'
    ((field = 'lower(slug)') and (arg = 'lower($1)')) if Forum.slug? slug_or_id

    result = query %{
      SELECT count(*) FROM Forum WHERE
      (#{field} = #{arg}) LIMIT 1;
      }, [slug_or_id]

    result[0]['count'].to_i != 0
  end


  def self.exists_with_title?(slug_or_id, title)
    field = 'id'
    arg = '$1'
    ((field = 'lower(slug)') and (arg = 'lower($1)')) if Forum.slug? slug_or_id

    result = query %{
      SELECT count(*) FROM Forum WHERE
      (#{field} = #{arg} OR lower(title) = $2) LIMIT 1;
      }, [slug_or_id, title.downcase]

    result[0]['count'].to_i != 0
  end

end