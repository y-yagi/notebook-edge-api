class PagesController < ApplicationController
  before_action :set_notebook
  before_action :set_page, only: [:show, :update, :destroy]

  def index = render json: my_pages(@notebook).order(:updated_at, :desc).order(:id, :desc)

  def show = render json: @page

  def create
    render json: my_pages(@notebook).create!(page_params), status: :created
  end

  def update
    @page.update!(page_params)
    render json: @page
  end

  def destroy
    @page.destroy
    head :no_content
  end

  private

  def set_notebook
    @notebook = my_notebook(params["notebook_id"])
  end

  def set_page
    @page = my_pages(@notebook).find(params["id"])
  end

  def page_params = params.require(:page).permit(:name, :content)
end
