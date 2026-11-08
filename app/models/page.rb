class Page < ApplicationModel
  attribute :user_id, :string
  attribute :notebook_id, :integer
  attribute :name, :string
  attribute :content, :string, default: ""
  timestamps

  validates :name, presence: true, length: { maximum: 200 }
  # D1 rows are at most 2,000,000 bytes; Japanese is 3 bytes a character in UTF-8.
  validates :content, length: { maximum: 600_000 }
end
