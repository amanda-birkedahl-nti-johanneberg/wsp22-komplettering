require 'sinatra'
require 'sinatra/reloader' if development?

# laddar in alla modeller
# https://stackoverflow.com/a/26320183
Dir.glob('models/*.rb') { |f| require_relative f }

# laddar om alla filer i models/
# http://sinatrarb.com/contrib/reloader
# https://www.freecodecamp.org/news/rubys-splat-and-double-splat-operators-ceb753329a78/
also_reload(*Dir.glob('models/*.rb'))

include Användare
include Todo
include Taggar

get '/' do
  slim :index
end
