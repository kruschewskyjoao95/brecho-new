class Question < ApplicationRecord
  belongs_to :product
  belongs_to :user

  validates :content, presence: true, length: { minimum: 5, maximum: 500 }
  validates :answer, length: { maximum: 500 }, allow_blank: true
end
