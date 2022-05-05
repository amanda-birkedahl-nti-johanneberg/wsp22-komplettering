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
# 3.1 Visa todo
# 3.2 Skapa todo
# 3.3 Uppdatera punkt
# 3.4 Raderar todo

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
  path = splat.split('/')[1]
  p Användare.hämta_med_namn(användare['namn']), användare
  anv = path.nil? ? Användare.hämta_med_namn(användare['namn']) : Användare.hämta_med_namn(path)

  slim :"konto/visa", locals: { user: anv }
end

# 3. Routes för todos

# 3.1 Visa todo

# 3.2 Skapa todo
before '/todo' do
  redirect '/' unless auth?
end

# Skapar en todo
#
# @param [String] titel
# @param [Hash] punkter
# @see Todo#skapa
post '/todo' do
  params = JSON.parse(request.body.read)
  redirect '/' if params['titel'].length < 3

  titel = params['titel']
  punkter = params['punkter']

  resultat = Todo.skapa(titel, punkter, användare)

  status 200
  redirect '/'
end

before '/todo/:id/*' do |id, _splat|
  return redirect '/logga-in' unless auth?

  Todo.har_tillåtelse(id.to_i, användare)
end

# 3.3 Uppdatera punkt

# Uppdaterar statusen på en punkt
#
# @param [String] id todons id
# @param [String] punkt punktens index
# @see Todo#hämta
# @see Todo#uppdatera
post '/todo/:id/punkt/:punkt' do |id, punkt|
  todo = Todo.hämta(id.to_i)
  todo['punkter'][punkt.to_i]['klar'] = true
  Todo.uppdatera(id.to_i, todo['punkter'])

  redirect '/'
end

# 3.4 Raderar todo

# Radera en todo
#
# @param [String] id todons id
post '/todo/:id/radera' do |id|
  id = id.to_i

  Todo.radera(id)

  status 204
  redirect '/'
end
