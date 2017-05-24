require_relative 'db/db'
require_relative 'migrations/create_db_schema'


%x(service postgresql start)

init(ENV['DB'])
drop
create


workers = 8

worker_list = []

workers.times do |i|
  worker_list.push "server 0.0.0.0:#{5001 + i}"
end


workers.times do |i|
  pid = spawn("ruby main.rb #{5001 + i}")
  Process.detach(pid)
end


File.open '/etc/nginx/sites-available/default', 'w' do |file|
  contents = %{
    upstream rubies {
        #{worker_list.join ";\n"};
    }

    server {
        listen 5000;

        location / {
            proxy_pass http://rubies;
        }
    }
  }

  puts contents
  p ''

  file.write contents
end

p %x(service nginx start)


sleep
