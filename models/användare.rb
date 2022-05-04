require 'bcrypt'

LOGGA_IN_FEL = { error: 'Användarnamnet eller lösenordet är fel', user: nil }.freeze

# Metoder för användare
#
module Användare
  # hämtar de 10 bästa användarna
  def hämta_top_10
    db.execute('SELECT namn, id, avklarade, misslyckade FROM users ORDER BY avklarade DESC LIMIT 10')
  end

  # Ser som ett användarnamn är registrerat
  #
  # @param [String] namn
  # @return [Boolean] om namnet är upptaget
  def existerar?(namn)
    db.execute('SELECT id FROM users WHERE namn = ?', namn)[0] != nil
  end

  # Loggar in en användare
  #
  # @param [String] namn
  # @param [String] lösenord
  # @return [Hash] resultat
  # @option resultat [nil, String] error
  # @option resultat [Hash, nil] user
  def logga_in(namn, lösenord)
    return LOGGA_IN_FEL unless existerar?(namn)

    hash = db.execute('SELECT password_hash FROM users WHERE namn = ?', namn)[0]['password_hash']
    matchar = BCrypt::Password.new(hash) == lösenord

    return LOGGA_IN_FEL unless matchar

    användare = db.execute('SELECT id, misslyckade, admin, avklarade, namn FROM users WHERE namn = ?', namn)[0]

    { error: nil, user: användare }
  end

  # Registrerar en användare
  #
  # @param [String] namn
  # @param [String] lösenord
  # @return [Hash] resultat
  # @option resultat [nil, String] error
  # @option resultat [Integer, nil] user
  def registrera(namn, lösenord)
    return { error: 'Användaren existerar redan', user: nil } if existerar?(namn)

    transaktion = db
    hash = BCrypt::Password.create(lösenord)
    transaktion.execute('INSERT INTO users (namn, password_hash) VALUES (?, ?)', namn, hash)
    { error: nil, user: transaktion.last_insert_row_id }
  end

  # Verifierar att kredentialerna är giltiga
  #
  # @param [String] namn
  # @param [String] lösenord
  def verifiera_kredentialer(namn, lösenord)
    return { error: 'Användarnamnet måste vara längre än 3 karaktärer' } unless namn.length > 3
    return { error: 'Lösenordet måste vara längre än 6 karaktärer' } unless lösenord.length > 3

    { error: nil }
  end

  # Hämtar data för en viss användare
  #
  # @param [String] namn
  # @return [Hash, nil] användare
  def hämta(namn)
    return nil unless existerar?(namn)

    db.execute('SELECT id, misslyckade, admin, avklarade, namn FROM users WHERE namn = ?', namn)[0]
  end

  def admin?(namn)
    return false unless existerar?(namn)

    db.execute('SELECT admin FROM users WHERE namn = ?', namn)[0]['admin'] == 1
  end
end
