require 'pg'

@conn = nil


def init(conn_str)
  @conn = PG.connect conn_str
end


def query(sql, params)
  sql = sql.gsub(/\s+/, ' ').strip
  @conn.exec sql, params || []
end