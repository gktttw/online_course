# == Schema Information
#
# Table name: chapters
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  course_id  :integer          not null
#  ordering   :float            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Chapter < ActiveRecord::Base
  validates :name, presence: true

  belongs_to :course
  has_many :units, dependent: :delete_all
  accepts_nested_attributes_for :units
end
