require 'pg'

$__conn__ = nil
$__statements__ = {}


def init(conn_str)
  $__conn__ = PG.connect conn_str
end


def time_diff(start, stop)
  (stop - start) * 1000.0
end


def query(sql, params = nil)
  sql = sql.gsub(/\s+/, ' ').strip

  start = Time.now
  result = $__conn__.exec sql, params
  stop = Time.now

  if $__statements__[sql]
    $__statements__[sql] = (time_diff(start, stop) + $__statements__[sql]) / 2
  else
    $__statements__[sql] = time_diff start, stop
  end

  result
end


def time_stats
  sorted = $__statements__.sort_by {|_key, value| value}
  stats = []

  sorted.each do |query|
    stats.push "#{query[1]}: '#{query[0]}'"
  end

  stats
end