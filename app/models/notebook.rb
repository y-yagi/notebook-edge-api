class Notebook < ApplicationModel
  attribute :user_id, :string
  attribute :name, :string
  timestamps
  has_many :pages
  validates :name, presence: true, length: { maximum: 100 }, format: { with: /\A[^\/]+\z/ }, uniqueness: { scope: :user_id }
end
