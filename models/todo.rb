module Todo
  def hämta_alla(klara = false)
    db.execute('SELECT * FROM todos WHERE status = ?', klara ? 2 : 1)
  end
end
