# Metoder för taggar
#
module Taggar
  # Skapar en tagg
  #
  # @param [String] namn
  def skapa_tagg(namn)
    db.execute('INSERT INTO taggar (titel) values(?)', namn)
  end

  # Hämtar alla taggar
  #
  # @return [Array<Hash>] alla taggar
  def hämta_alla
    db.execute('SELECT * FROM taggar')
  end

  # Raderar en tagg
  #
  # @param [Integer] tagg_id
  def ta_bort(tagg_id)
    db.execute('DELETE FROM todo_taggar WHERE tagg_id = ?', tagg_id)
    db.execute('DELETE FROM taggar WHERE id = ?', tagg_id)
  end
end
