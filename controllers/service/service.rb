require 'sinatra'
require_relative '../../db/db'
require_relative '../../migrations/create_db_schema'


post '/api/service/clear' do
  drop
  create
end
