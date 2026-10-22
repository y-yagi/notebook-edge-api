require "edgeway/test"
require "test_helper"

class NotebooksTest < Edgeway::IntegrationTest
  def alice = auth_headers("uid-alice")
  def bob = auth_headers("uid-bob")

  def test_needs_a_token
    get "/notebooks"
    assert_response 401
  end

  def test_rejects_an_unknown_token
    get "/notebooks", headers: { "Authorization" => "Bearer forged" }
    assert_response 401
  end

  def test_index_makes_the_default_notebook
    get "/notebooks", headers: alice
    assert_response 200
    assert_equal ["default"], json.map { |n| n["name"] }
    get "/notebooks", headers: alice
    assert_equal 1, Notebook.count
  end

  def test_index_is_by_name_and_only_mine
    post "/notebooks", json: { "name" => "work" }, headers: alice
    post "/notebooks", json: { "name" => "blog" }, headers: alice
    post "/notebooks", json: { "name" => "secret" }, headers: bob
    get "/notebooks", headers: alice
    assert_equal ["blog", "default", "work"], json.map { |n| n["name"] }
    assert_equal "uid-alice", json[0]["user_id"]
  end

  def test_create
    post "/notebooks", json: { "name" => "日記" }, headers: alice
    assert_response 201
    assert_equal "日記", json["name"]
    assert_equal "uid-alice", json["user_id"]
  end

  def test_create_is_idempotent
    post "/notebooks", json: { "name" => "work" }, headers: alice
    id = json["id"]
    post "/notebooks", json: { "name" => "work" }, headers: alice
    assert_response 201
    assert_equal id, json["id"]
    assert_equal 1, Notebook.count
  end

  def test_the_same_name_for_another_user_is_another_notebook
    post "/notebooks", json: { "name" => "work" }, headers: alice
    id = json["id"]
    post "/notebooks", json: { "name" => "work" }, headers: bob
    assert json["id"] != id
  end

  def test_create_rejects_a_bad_name
    post "/notebooks", json: { "name" => "a/b" }, headers: alice
    assert_response 422
    post "/notebooks", json: { "name" => "" }, headers: alice
    assert_response 422
  end

  def test_create_needs_a_name
    post "/notebooks", json: {}, headers: alice
    assert_response 400
  end

  def test_user_id_in_the_body_is_ignored
    post "/notebooks", json: { "name" => "work", "user_id" => "uid-bob" }, headers: alice
    assert_equal "uid-alice", json["user_id"]
  end

  def test_destroy
    post "/notebooks", json: { "name" => "work" }, headers: alice
    delete "/notebooks/work", headers: alice
    assert_response 204
    assert_equal 0, Notebook.count
  end

  def test_destroy_keeps_the_default_notebook
    get "/notebooks", headers: alice
    delete "/notebooks/default", headers: alice
    assert_response 422
    assert_equal 1, Notebook.count
  end

  def test_destroy_keeps_a_notebook_with_pages
    post "/notebooks", json: { "name" => "work" }, headers: alice
    post "/notebooks/work/pages", json: { "name" => "memo" }, headers: alice
    delete "/notebooks/work", headers: alice
    assert_response 409
    assert_equal 1, Notebook.count
  end

  def test_destroy_of_someone_elses_notebook_is_not_found
    post "/notebooks", json: { "name" => "work" }, headers: alice
    delete "/notebooks/work", headers: bob
    assert_response 404
    assert_equal 1, Notebook.count
  end
end
