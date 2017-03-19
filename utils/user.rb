require_relative '../db/db'


module User

  def self.exists?(nickname)
    result = query %q{
       SELECT id FROM ForumUser as u WHERE (lower(u.nickname) = $1) LIMIT 1;
                   }, [nickname.downcase]
    return false if result.ntuples == 0
    return result[0]['id'].to_i
  end


  def self.exists_email?(email)
    result = query %q{
      SELECT COUNT(*) FROM ForumUser as u WHERE
      (lower(u.email) = $1) LIMIT 1;
                   }, [email.downcase]
    return result[0]['count'].to_i != 0
  end


  def self.exists_with_email?(nickname, email)
    result = query %q{
      SELECT COUNT(*) FROM ForumUser as u WHERE
      (lower(u.nickname) = $1 OR lower(u.email) = $2) LIMIT 1;
                   }, [nickname.downcase, email.downcase]
    return result[0]['count'].to_i != 0
  end


  def self.by_nickname(nickname)
    result = query %q{
        SELECT id FROM ForumUser WHERE nickname = $1 LIMIT 1;
      }, [nickname]

    return result[0]['id']
  end


  def self.by_id(id)
    result = query %q{
        SELECT nickname FROM ForumUser WHERE id = $1 LIMIT 1;
      }, [id]

    return result[0]['nickname']
  end

end

