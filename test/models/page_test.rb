require "edgeway/test"
require "test_helper"

class PageTest < Edgeway::UnitTest
  def notebook(uid = "uid-a") = Notebook.create(user_id: uid, name: "default")

  def test_create
    n = notebook
    p = Page.create(user_id: "uid-a", notebook_id: n.id, name: "memo", content: "# hi")
    assert p.persisted?
    assert_equal 1, n.pages.count
  end

  def test_content_defaults_to_empty
    p = Page.create(user_id: "uid-a", notebook_id: notebook.id, name: "memo")
    assert_equal "", Page.find(p.id).content
  end

  def test_name_is_required
    assert !Page.create(user_id: "uid-a", notebook_id: notebook.id, name: "").persisted?
  end

  def test_content_is_at_most_600_000_characters
    n = notebook
    assert Page.create(user_id: "uid-a", notebook_id: n.id, name: "a", content: "あ" * 600_000).persisted?
    assert !Page.create(user_id: "uid-a", notebook_id: n.id, name: "b", content: "あ" * 600_001).persisted?
  end

  def test_a_page_cannot_be_in_another_users_notebook
    n = notebook("uid-a")
    assert_raise(Edgeway::DatabaseError) { Page.create(user_id: "uid-b", notebook_id: n.id, name: "memo") }
  end

  def test_a_page_needs_an_existing_notebook
    assert_raise(Edgeway::DatabaseError) { Page.create(user_id: "uid-a", notebook_id: 999, name: "memo") }
  end

  def test_a_notebook_with_pages_cannot_be_deleted
    n = notebook
    Page.create(user_id: "uid-a", notebook_id: n.id, name: "memo")
    assert_raise(Edgeway::DatabaseError) { n.destroy }
  end

  def test_newest_first_and_id_breaks_ties
    n = notebook
    Edgeway::Model.freeze_time("2026-10-22T00:00:00.000Z")
    Page.create(user_id: "uid-a", notebook_id: n.id, name: "a")
    Page.create(user_id: "uid-a", notebook_id: n.id, name: "b")
    Edgeway::Model.freeze_time("2026-10-21T00:00:00.000Z")
    Page.create(user_id: "uid-a", notebook_id: n.id, name: "c")
    Edgeway::Model.freeze_time(nil)
    names = Page.where(notebook_id: n.id).order(:updated_at, :desc).order(:id, :desc).to_a.map(&:name)
    assert_equal ["b", "a", "c"], names
  end
end
