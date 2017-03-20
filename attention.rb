require 'sinatra'
require_relative 'db/db'
require_relative 'migrations/create_db_schema'

require_relative 'controllers/forum/forum'
require_relative 'controllers/user/user'
require_relative 'controllers/thread/thread'
require_relative 'controllers/post/post'
require_relative 'controllers/service/service'


after do
  content_type :json
end


def hello(name)
  p 'Hello, Human! Long time no see'
end


def can(who)
  who
end

def ask(whom)
  whom
end

def to(what)
  what
end

def launch(what)
  what
end

def a(what)
  what
end

def i(what)
  what
end

def you(to)
  to
end


def webapp?
end



def please(func_res)
  func_res
end


def also(func_res)
  func_res
end

def listen(to: '')
  to = to.split ':'

  set bind: to[0]
  set port: to[1].to_i

  p "I'm going to listen to #{to[0]}:#{to[1].to_s}"
end



def use(what_res)
  what_res
end

def port(p)
  set port: p
end



def database(connection_res)
  connection_res
end

def connection(setup_res)
  setup_res
end

def setup(can_res)
  can_res
end

def be(found_res)
  found_res
end

def found(at: '')
  p "I'm going to connect to '#{at}'"
  init(at)
end


def choose(what, from: '')
  set :server, from
end

def thank(who)
  who
end

def lot!
  p 'Love you <3'
  set :show_exceptions, false

  drop
  create
end

