require 'sinatra'
require 'sinatra/reloader' if development?

# laddar in alla modeller
# https://stackoverflow.com/a/26320183
Dir.glob('models/*.rb') { |f| require_relative f }
require_relative 'utils'

# laddar om alla filer i models/
# http://sinatrarb.com/contrib/reloader
# https://www.freecodecamp.org/news/rubys-splat-and-double-splat-operators-ceb753329a78/
also_reload(*Dir.glob('models/*.rb'), 'utils.rb')

include Utils

include Användare
include Todo
include Taggar

enable :sessions

# STRUKTUR (ctrl+f)
# 1. Förstasidan
# 2. Routes för användare
# 2.1 Logga in
# 2.2 Skapa konto
# 2.3 Logga ut
# 2.4 Radera konto
# 2.5 Visa konto
# 3. Routes för todos

# Visar förstasidan
#
# @see Todo#hämta_alla_för_användare
# @see Användare#hämta_top_10
get '/' do
  todos = auth? ? Todo.hämta_alla_för_användare(false, användare) : []
  users = Användare.hämta_top_10

  slim :index, locals: { top_users: users, my_todos: todos }
end

# 2. Routes för användare

# 2.1 Logga in

# Visar inloggningssidan
#
get '/logga-in' do
  slim :"konto/logga-in"
end

# Loggar in
#
# @param [String] namn
# @param [String] lösenord
#
# @see Användare#verifiera_kredentialer
# @see Användare#logga_in
post '/konto/logga-in' do
  namn = params[:namn]
  lösenord = params[:lösenord]

  kredentialer = Användare.verifiera_kredentialer(namn, lösenord)

  unless kredentialer[:error].nil?
    session[:logga_in_fel] = LOGGA_IN_FEL[:error]

    status 400
    return redirect '/logga-in'
  end

  resultat = Användare.logga_in(namn, lösenord)

  unless resultat[:error].nil?
    session[:logga_in_fel] = LOGGA_IN_FEL[:error]

    status 403
    return redirect '/logga-in'

  end

  session[:användare] = resultat[:user]
  session[:logga_in_fel] = nil

  status 200
  redirect '/'
end

# 2.2 Skapa konto

# Visar skapa konto sidan
get '/skapa-konto' do
  slim :"konto/skapa-konto"
end

# Skapar ett konto
#
# @param [String] namn
# @param [String] lösenord
#
# @see Användare#verifiera_kredentialer
# @see Användare#registrera
# @see Användare#logga_in
post '/konto/skapa-konto' do
  namn = params[:namn]
  lösenord = params[:lösenord]

  kredentialer = Användare.verifiera_kredentialer(namn, lösenord)

  unless kredentialer[:error].nil?
    session[:skapa_konto_fel] = kredentialer[:error]

    status 400
    return redirect '/skapa-konto'
  end

  resultat = Användare.registrera(namn, lösenord)

  unless resultat[:error].nil?
    session[:skapa_konto_fel] = resultat[:error]

    status 403
    return redirect '/skapa-konto'

  end

  # logga in också
  resultat = Användare.logga_in(namn, lösenord)

  session[:användare] = resultat[:user]
  session[:skapa_konto_fel] = nil

  status 200
  redirect '/'
end

# 2.3 Logga ut

# loggar ut användaren
#
post '/konto/logga-ut' do
  session&.destroy
  redirect '/'
end

# 2.4 Radera konto

# Raderar ett konto
#
# @param [String] id
post '/konto/:id/radera' do
end

# 2.5 Visa konto

# om url är /konto/hejhej, gå till användaren hejhejs profil
# om url är /konto/ eller /konto och användaren är utloggad,
# gå till inlogg sida
#
# @param [String] splat
before '/konto*' do |splat|
  redirect '/logga-in' if (splat.split('/') - ['/']).empty? && !auth?
end

# Visar kontosidan för en användare
#
# @param [String] splat
# @see Användare#hämta
get '/konto*' do |splat|
  anv = Användare.hämta(splat.split('/')[1] || användare['namn'])

  slim :"konto/visa", locals: { user: anv }
end

# 3. Routes för todos
