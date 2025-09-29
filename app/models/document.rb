class Document < ApplicationRecord
  has_one_attached :pdf
  has_many_attached :images  # extracted or user-uploaded replacements
end