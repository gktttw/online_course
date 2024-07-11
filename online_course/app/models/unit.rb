# == Schema Information
#
# Table name: units
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  description :string
#  content     :string           not null
#  ordering    :float            not null
#  chapter_id  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Unit < ApplicationRecord
  validates :name, :content, :ordering, presence: true
  belongs_to :chapter
end
