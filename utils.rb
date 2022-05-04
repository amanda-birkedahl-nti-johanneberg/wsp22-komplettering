require 'sqlite3'

# Funktioner för att underlätta i slim och guard-filer
#
module Utils
  # För att slippa skriva session[:användare] != nil;
  #
  # @return [Boolean] finns det en session?
  def auth?
    session[:användare] != nil
  end

  # Returnerar användaren
  #
  # @return [Hash] användaren
  def användare
    auth? ? session[:användare] : {}
  end

  # Checkar om användaren är samma som jag själv
  #
  # @param [Hash] anv
  # @return [Boolean] är det jag?
  def jag?(anv)
    return false if anv.nil? || !auth?
    return true if användare['id'] == anv['id']

    false
  end

  # Skapar och konfigurerar anslutningen till databasen
  #
  # @return [SQLite3::Database]
  def db
    db = SQLite3::Database.new 'databas.db'
    db.results_as_hash = true
    db
  end
end
