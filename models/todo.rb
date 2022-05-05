require 'json'

# Metoder för todos
#
module Todo
  # Hämtar en todo efter id
  #
  # @param [Integer] id
  # @return [Hash, nil]
  def hämta(id)
    todos = db.execute('SELECT * FROM todos WHERE id = ?', id)
    return nil if todos.empty?

    todo = todos[0]
    todo['punkter'] = JSON.parse(todo['punkter'])
    todo
  end

  # Hämtar alla todo för en användare
  #
  # @param [Boolean] klara
  # @param [Hash] anv användaren
  # @return [Array<Hash>]
  def hämta_alla_för_användare(klara = false, anv)
    db.execute('SELECT * FROM todos WHERE user_id = ? and status = ?', anv['id'], klara ? 2 : 1).map do |todo|
      todo['punkter'] = JSON.parse(todo['punkter'])
      todo
    end
  end

  # Skapar en ny TODO
  #
  # @param [String] titel
  # @param [Array<Hash>] punkter
  # @param [Hash] anv Användaren
  def skapa(titel, punkter, anv)
    databas_punkter = JSON.generate(punkter)
    db.execute('INSERT INTO TODOS (titel, punkter, user_id) values(?, ?, ?)', titel, databas_punkter, anv['id'])
  end

  # uppdaterar en TODO
  #
  # @param [Integer] todo_id
  # @param [Array<Hash>] punkter
  def uppdatera(todo_id, punkter)
    databas_punkter = JSON.generate(punkter)
    is_done = punkter.find { |punkt| punkt['klar'] == false }.nil?

    db.execute('UPDATE todos SET punkter = ?, status = ? WHERE id = ?', databas_punkter, is_done ? 2 : 1, todo_id)

    return unless is_done

    user_id = db.execute('SELECT user_id FROM todos WHERE id = ?', todo_id)[0]['user_id']
    db.execute('UPDATE users SET avklarade = avklarade + 1 WHERE id = ?', user_id)
  end

  # Tar bort en TODO och lägger till i misslyckade
  #
  # @param [Integer] todo_id
  def radera(todo_id)
    user_id = db.execute('SELECT user_id FROM todos WHERE id = ?', todo_id)[0]['user_id']
    db.execute('DELETE FROM todos WHERE id = ?', todo_id)

    db.execute('UPDATE users SET misslyckade = misslyckade + 1 WHERE id = ?', user_id)
  end

  # Check om användaren har tillgång till en todo
  #
  # @param [Integer] todo_id
  # @param [Hash] användare
  def har_tillåtelse(todo_id, användare)
    todos = db.execute('SELECT user_id FROM todos WHERE id = ?', todo_id)
    return false if todos.empty?

    todos[0]['user_id'] == användare['id']
  end
end
