require 'rails_helper'

RSpec.describe Course, type: :model do
  describe '#to_json_with_associations' do
    let(:course_with_associations) { FactoryBot.create(:course, :with_chapters_and_units, chapters_count: 2, units_count: 2) }

    it 'returns course with associations' do
      json_string = course_with_associations.to_json_with_associations

      h = JSON.load(json_string)
      expect(h['id']).to eq(course_with_associations.id)

      expect(h['chapters'].size).to eq(2)
      expect(h['chapters'].map{ _1['id'] }).to eq(course_with_associations.chapters.map(&:id))
      h['chapters'].each do |chapter|
        expect(chapter['units'].size).to eq(2)
        expect(chapter['units'].map{ _1['id'] }).to eq(course_with_associations.chapters.find(chapter['id']).units.map(&:id))
      end
    end
  end
end
