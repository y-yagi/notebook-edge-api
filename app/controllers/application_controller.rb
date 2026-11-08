class ApplicationController < Edgeway::Controller::Base
  rescue_from Edgeway::RecordNotFound, with: :not_found

  before_action :authenticate!

  private

  def not_found(e)
    render json: { "error" => "not found" }, status: :not_found
  end

  def current_user_id = current_claims["sub"]

  def notebooks = Notebook.where(user_id: current_user_id)

  def notebook(name)
    notebooks.find_by(name: name) || raise(Edgeway::RecordNotFound, "notebook not found")
  end

  def pages(notebook) = Page.where(user_id: current_user_id, notebook_id: notebook.id)
end
