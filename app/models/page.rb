class Page < ApplicationModel
  # D1 rows are at most 2,000,000 bytes. Count bytes, not characters: an emoji is
  # 4 bytes in UTF-8. The rest is left for the other columns (name is at most 200 characters).
  CONTENT_MAX_BYTES = 1_900_000

  attribute :user_id, :string
  attribute :notebook_id, :integer
  attribute :name, :string
  attribute :content, :string, default: ""
  timestamps

  validates :name, presence: true, length: { maximum: 200 }

  # Edgeway's length validation counts characters for a :string column, and it has no custom validations.
  def valid?
    super
    text = content
    errors << "content is too long (maximum is #{CONTENT_MAX_BYTES} bytes)" if !text.nil? && text.bytesize > CONTENT_MAX_BYTES
    errors.empty?
  end
end
