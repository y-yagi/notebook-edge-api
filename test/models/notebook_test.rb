require "edgeway/test"
require "test_helper"

class NotebookTest < Edgeway::UnitTest
  def test_create
    n = Notebook.create(user_id: "uid-a", name: "default")
    assert n.persisted?
    assert_equal "uid-a", n.user_id
    assert !n.created_at.nil?
  end

  def test_name_is_required
    n = Notebook.create(user_id: "uid-a", name: "")
    assert !n.persisted?
  end

  def test_name_cannot_have_a_slash
    n = Notebook.create(user_id: "uid-a", name: "a/b")
    assert !n.persisted?
  end

  def test_name_cannot_be_a_dot_segment
    assert !Notebook.create(user_id: "uid-a", name: ".").persisted?
    assert !Notebook.create(user_id: "uid-a", name: "..").persisted?
    assert Notebook.create(user_id: "uid-a", name: "...").persisted?
    assert Notebook.create(user_id: "uid-a", name: ".hidden").persisted?
  end

  def test_name_is_at_most_100_characters
    assert Notebook.create(user_id: "uid-a", name: "あ" * 100).persisted?
    assert !Notebook.create(user_id: "uid-a", name: "あ" * 101).persisted?
  end

  def test_name_is_unique_per_user
    Notebook.create(user_id: "uid-a", name: "work")
    assert !Notebook.create(user_id: "uid-a", name: "work").persisted?
    assert Notebook.create(user_id: "uid-b", name: "work").persisted?
  end

  def test_the_unique_constraint_backs_the_validation
    Notebook.create(user_id: "uid-a", name: "work")
    sql = "INSERT INTO notebooks (user_id, name) VALUES (?, ?)"
    assert_raise(Edgeway::RecordNotUnique) { Edgeway::Model.connection.execute(sql, ["uid-a", "work"]) }
  end

  def test_find_or_create_by_scopes_to_the_user
    a = Notebook.where(user_id: "uid-a").find_or_create_by(name: "default")
    assert_equal a.id, Notebook.where(user_id: "uid-a").find_or_create_by(name: "default").id
    b = Notebook.where(user_id: "uid-b").find_or_create_by(name: "default")
    assert b.id != a.id
    assert_equal "uid-b", b.user_id
  end
end
