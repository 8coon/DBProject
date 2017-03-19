require 'pg'

$__conn__ = nil


def init(conn_str)
  $__conn__ = PG.connect conn_str
end


def query(sql, params)
  sql = sql.gsub(/\s+/, ' ').strip
  $__conn__.exec sql, params || []
end