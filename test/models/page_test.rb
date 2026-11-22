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

  def test_content_is_at_most_1_900_000_bytes
    n = notebook
    assert Page.create(user_id: "uid-a", notebook_id: n.id, name: "a", content: "a" * 1_900_000).persisted?
    p = Page.create(user_id: "uid-a", notebook_id: n.id, name: "b", content: "a" * 1_900_001)
    assert !p.persisted?
    assert_equal ["content is too long (maximum is 1900000 bytes)"], p.errors
  end

  def test_content_limit_counts_bytes_not_characters
    n = notebook
    # 475,000 emoji are 1,900,000 bytes; one more is over, though far below 600,000 characters.
    assert Page.create(user_id: "uid-a", notebook_id: n.id, name: "a", content: "😀" * 475_000).persisted?
    assert !Page.create(user_id: "uid-a", notebook_id: n.id, name: "b", content: "😀" * 475_001).persisted?
  end

  def test_content_limit_keeps_other_errors
    p = Page.create(user_id: "uid-a", notebook_id: notebook.id, name: "", content: "a" * 1_900_001)
    assert_equal 2, p.errors.size
  end

  def test_a_page_cannot_be_in_another_users_notebook
    n = notebook("uid-a")
    assert_raise(Edgeway::InvalidForeignKey) { Page.create(user_id: "uid-b", notebook_id: n.id, name: "memo") }
  end

  def test_a_page_needs_an_existing_notebook
    assert_raise(Edgeway::InvalidForeignKey) { Page.create(user_id: "uid-a", notebook_id: 999, name: "memo") }
  end

  def test_a_notebook_with_pages_cannot_be_deleted
    n = notebook
    Page.create(user_id: "uid-a", notebook_id: n.id, name: "memo")
    assert_raise(Edgeway::InvalidForeignKey) { n.destroy }
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
