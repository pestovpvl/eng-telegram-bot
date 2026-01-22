class Pack < ActiveRecord::Base
  has_many :words, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
