# == Schema Information
#
# Table name: courses
#
#  id            :bigint           not null, primary key
#  name          :string           not null
#  lecturer_name :string           not null
#  description   :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Course < ActiveRecord::Base
  validates :name, :lecturer_name, presence: true

  has_many :chapters, dependent: :delete_all
  has_many :units, through: :chapters
  accepts_nested_attributes_for :chapters

  def to_json_with_associations
    course_with_associations = Course.includes(chapters: :units).find(self.id)
    course_with_associations.to_json(include: { chapters: { include: :units } })
  end
end
