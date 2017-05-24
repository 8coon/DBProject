require 'sinatra'
require_relative 'attention'


hello :Computer!

can i ask you to launch a webapp?
please listen to: "0.0.0.0:#{ARGV[0]}"
database connection setup can be found at: ENV['DB'] || 'postgresql://localhost:5432/coon'
you can choose :webserver, from: %w[thin webrick]

thank you a lot!
