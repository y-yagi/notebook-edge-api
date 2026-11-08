class NotebooksController < ApplicationController
  DEFAULT_NAME = "default"

  def index
    notebooks.find_or_create_by!(name: DEFAULT_NAME)
    render json: notebooks.order(:name)
  end

  def create
    name = params.require(:notebook).permit(:name)["name"]
    render json: notebooks.find_or_create_by!(name: name), status: :created
  end

  def destroy
    notebook = notebook(params["id"])
    if notebook.name == DEFAULT_NAME
      render json: { "error" => "the default notebook cannot be deleted" }, status: :unprocessable_entity
    elsif pages(notebook).count > 0
      render json: { "error" => "the notebook has pages" }, status: :conflict
    else
      notebook.destroy
      head :no_content
    end
  end
end
