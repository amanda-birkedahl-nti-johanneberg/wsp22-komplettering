module Todo
  def hämta_alla(klara = false)
    db.execute('SELECT * FROM todos WHERE status = ?', klara ? 2 : 1)
  end

  def hämta_alla_för_användare(klara = false, anv)
    db.execute('SELECT * FROM todos WHERE user_id = ? and status = ?', anv['id'], klara ? 2 : 1)
  end

  def skapa(titel, punkter, anv)
    databas_punkter = punkter.to_json
    db.execute('INSERT INTO TODOS (titel, punkter, user_id) values(?, ?, ?)', titel, databas_punkter, anv['id'])
  end
end
