require "edgeway/test"
require "test_helper"

class PagesTest < Edgeway::IntegrationTest
  def alice = auth_headers("uid-alice")
  def bob = auth_headers("uid-bob")

  def setup
    super
    post "/notebooks", json: { "name" => "work" }, headers: alice
  end

  def create_page(name, content = "")
    post "/notebooks/work/pages", json: { "name" => name, "content" => content }, headers: alice
    json["id"]
  end

  def test_needs_a_token
    get "/notebooks/work/pages"
    assert_response 401
  end

  def test_create
    post "/notebooks/work/pages", json: { "name" => "memo", "content" => "# 見出し\n本文" }, headers: alice
    assert_response 201
    assert_equal "memo", json["name"]
    assert_equal "# 見出し\n本文", json["content"]
    assert_equal "uid-alice", json["user_id"]
    assert_equal Notebook.find_by(name: "work").id, json["notebook_id"]
  end

  def test_create_rejects_a_page_without_a_name
    post "/notebooks/work/pages", json: { "name" => "" }, headers: alice
    assert_response 422
  end

  def test_create_in_an_unknown_notebook_is_not_found
    post "/notebooks/nothing/pages", json: { "name" => "memo" }, headers: alice
    assert_response 404
  end

  def test_body_cannot_choose_the_user_or_notebook
    post "/notebooks", json: { "name" => "other" }, headers: alice
    other = json["id"]
    post "/notebooks/work/pages", json: { "name" => "memo", "user_id" => "uid-bob", "notebook_id" => other },
                                  headers: alice
    assert_response 201
    assert_equal "uid-alice", json["user_id"]
    assert_equal Notebook.find_by(name: "work").id, json["notebook_id"]
  end

  def test_index_is_newest_first
    Edgeway::Model.freeze_time("2026-10-22T00:00:00.000Z")
    a = create_page("a")
    b = create_page("b")
    Edgeway::Model.freeze_time("2026-10-21T00:00:00.000Z")
    c = create_page("c")
    Edgeway::Model.freeze_time("2026-10-23T00:00:00.000Z")
    patch "/notebooks/work/pages/#{c}", json: { "content" => "updated" }, headers: alice
    Edgeway::Model.freeze_time(nil)
    get "/notebooks/work/pages", headers: alice
    assert_response 200
    assert_equal [c, b, a], json.map { |p| p["id"] }
  end

  def test_index_is_only_the_notebooks_pages
    create_page("in work")
    post "/notebooks", json: { "name" => "other" }, headers: alice
    post "/notebooks/other/pages", json: { "name" => "in other" }, headers: alice
    get "/notebooks/work/pages", headers: alice
    assert_equal ["in work"], json.map { |p| p["name"] }
  end

  def test_show
    id = create_page("memo", "body")
    get "/notebooks/work/pages/#{id}", headers: alice
    assert_response 200
    assert_equal "body", json["content"]
  end

  def test_show_through_another_notebook_is_not_found
    id = create_page("memo")
    post "/notebooks", json: { "name" => "other" }, headers: alice
    get "/notebooks/other/pages/#{id}", headers: alice
    assert_response 404
  end

  def test_update
    id = create_page("memo", "old")
    patch "/notebooks/work/pages/#{id}", json: { "name" => "renamed", "content" => "new" }, headers: alice
    assert_response 200
    assert_equal "renamed", json["name"]
    assert_equal "new", Page.find(id).content
  end

  def test_update_rejects_a_too_long_content
    id = create_page("memo")
    patch "/notebooks/work/pages/#{id}", json: { "content" => "a" * 600_001 }, headers: alice
    assert_response 422
  end

  def test_destroy
    id = create_page("memo")
    delete "/notebooks/work/pages/#{id}", headers: alice
    assert_response 204
    assert_equal 0, Page.count
  end

  def test_someone_elses_pages_are_not_found
    id = create_page("memo", "secret")
    post "/notebooks", json: { "name" => "work" }, headers: bob
    get "/notebooks/work/pages", headers: bob
    assert_equal 0, json.length
    get "/notebooks/work/pages/#{id}", headers: bob
    assert_response 404
    patch "/notebooks/work/pages/#{id}", json: { "content" => "stolen" }, headers: bob
    assert_response 404
    delete "/notebooks/work/pages/#{id}", headers: bob
    assert_response 404
    assert_equal "secret", Page.find(id).content
  end
end
