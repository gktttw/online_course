require 'rails_helper'

RSpec.describe ManageCourseService, type: :service do
  let(:course) { create(:course) }
  let(:chapter) { create(:chapter, course: course) }
  let(:unit) { create(:unit, chapter: chapter) }

  describe '#get_all' do
    it 'returns all courses with chapters and units' do
      course
      chapter
      unit
      result = ManageCourseService.new.get_all
      expect(result).to include(course.name)
      expect(result).to include(chapter.name)
      expect(result).to include(unit.name)
    end
  end

  describe '#show_one' do
    context 'when the course exists' do
      it 'returns the course with chapters and units' do
        course
        chapter
        unit
        service = ManageCourseService.new(payload: { id: course.id })
        result = service.show_one
        expect(result).to include(course.name)
        expect(result).to include(chapter.name)
        expect(result).to include(unit.name)
      end
    end

    context 'when the course does not exist' do
      it 'raises an error' do
        service = ManageCourseService.new(payload: { id: -1 })
        expect { service.show_one }.to raise_error(ManageCourseService::Error)
      end
    end
  end

  describe '#create' do
    let(:valid_course_params) { attributes_for(:course).merge(chapters_attributes: [attributes_for(:chapter, units_attributes: [attributes_for(:unit).except(:ordering)]).except(:ordering)]) }
    let(:service) { ManageCourseService.new(payload: valid_course_params) }

    it 'creates a new course with chapters and units' do
      expect {
        service.create
      }.to change { Course.count }.by(1)
        .and change { Chapter.count }.by(1)
        .and change { Unit.count }.by(1)
    end

    context 'when the course is invalid' do
      let(:invalid_course_params) { attributes_for(:course, name: nil) }
      let(:service) { ManageCourseService.new(payload: invalid_course_params) }

      it 'raises an error' do
        expect { service.create }.to raise_error(ManageCourseService::Error)
      end
    end
  end

  describe '#update' do
    let(:valid_course_params) { attributes_for(:course).merge(chapters_attributes: [attributes_for(:chapter, units_attributes: [attributes_for(:unit)])]) }
    context 'when the course exists' do
      it 'updates the course with new attributes' do
        course
        service = ManageCourseService.new(payload: valid_course_params.merge(id: course.id, name: 'Updated Name'))
        result = service.update
        expect(result).to include('Updated Name')
      end

      it 'when no attributes are given it stays the same' do
        course = create(:course, :with_chapters_and_units, chapters_count: 1, units_count: 1)
        before_json = course.to_json
        payload = {id: course.id}
        ManageCourseService.new(payload: payload).update
        expect(before_json).to eq(course.reload.to_json)
      end

      context 'target course has chapters and units' do
        context 'when given chapters_attributes' do
          it 'empty chapters_attributes will clear relations' do
            course = create(:course, :with_chapters_and_units, chapters_count: 1, units_count: 1)
            payload = {id: course.id, chapters_attributes: []}
            ManageCourseService.new(payload: payload).update
            expect(course.reload.chapters).to be_empty
            expect(course.reload.units).to be_empty
          end

          it 'chapters_attributes with both new and old chapters create, update, delete chapters simultaneously' do
            course = create(:course, :with_chapters_and_units, chapters_count: 2, units_count: 1)
            old_chapter_id = course.chapters.first.id
            old_chapter_id_to_be_delete = course.chapters.second.id
            payload = {id: course.id, chapters_attributes: [
              attributes_for(:chapter, name: 'new chapter', units_attributes: [attributes_for(:unit, name: 'new unit')]),
              {
                id: course.chapters.first.id,
                name: 'updated chapter',
              }
            ]}
            ManageCourseService.new(payload: payload).update
            expect(course.reload.chapters.length).to eq(2)
            expect(Chapter.find(old_chapter_id).name).to eq('updated chapter')
            new_chapter = course.chapters.detect { _1[:id] != old_chapter_id }
            expect(new_chapter.name).to eq('new chapter')
            expect(new_chapter.units.first.name).to eq('new unit')
            expect{Chapter.find(old_chapter_id_to_be_delete)}.to raise_error(ActiveRecord::RecordNotFound)
          end

          it 'chapters_attributes with only new chapters deletes all old ones and create new ones' do
            course = create(:course, :with_chapters_and_units, chapters_count: 2, units_count: 1)
            old_chapter_ids = course.chapters.map(&:id)
            payload = {id: course.id, chapters_attributes: [
              attributes_for(:chapter, name: 'new chapter 1', units_attributes: [attributes_for(:unit, name: 'new unit 1')]),
              attributes_for(:chapter, name: 'new chapter 2', units_attributes: [attributes_for(:unit, name: 'new unit 2')])
            ]}
            ManageCourseService.new(payload: payload).update
            expect(course.reload.chapters.length).to eq(2)
            expect{Chapter.find(old_chapter_ids.first)}.to raise_error(ActiveRecord::RecordNotFound)
            expect{Chapter.find(old_chapter_ids.second)}.to raise_error(ActiveRecord::RecordNotFound)
            expect(course.reload.chapters.first.name).to eq('new chapter 1')
            expect(course.reload.chapters.second.name).to eq('new chapter 2')
          end
        end

        context 'when given units_attributes' do
          it 'updates old units attr' do
            course = create(:course, :with_chapters_and_units, chapters_count: 2, units_count: 1)
            old_unit_id = course.chapters.first.units.first.id
            payload = {id: course.id, chapters_attributes: [
              {
                id: course.chapters.first.id,
                units_attributes: [
                  {
                    id: course.chapters.first.units.first.id,
                    name: 'updated unit'
                  }
                ]
              },
              {
                id: course.chapters.second.id,
              }
            ]}
            ManageCourseService.new(payload: payload).update
            expect(Unit.find(old_unit_id).name).to eq('updated unit')
            expect(course.reload.chapters.length).to eq(2)
            # it should stays the same
            expect(course.reload.chapters.second.units.length).to eq(1)
          end

          it 'create, update, delete units simultaneously' do
            course = create(:course, :with_chapters_and_units, chapters_count: 1, units_count: 2)
            old_unit_id = course.chapters.first.units.first.id
            old_unit_id_to_be_delete = course.chapters.first.units.second.id
            payload = {id: course.id, chapters_attributes: [
              {
                id: course.chapters.first.id,
                units_attributes: [
                  attributes_for(:unit, name: 'new unit 1'),
                  {
                    id: course.chapters.first.units.first.id,
                    name: 'updated unit'
                  }
                ]
              }
            ]}
            ManageCourseService.new(payload: payload).update
            expect(course.reload.chapters.first.units.length).to eq(2)
            expect(Unit.find(old_unit_id).name).to eq('updated unit')
            new_unit = course.chapters.first.units.detect { _1[:id] != old_unit_id }
            expect(new_unit.name).to eq('new unit 1')
            expect{Unit.find(old_unit_id_to_be_delete)}.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    context 'when the course does not exist' do
      it 'raises an error' do
        service = ManageCourseService.new(payload: valid_course_params.merge(id: -1))
        expect { service.update }.to raise_error(ManageCourseService::Error)
      end
    end
  end

  describe '#destroy' do
    context 'when the course exists' do
      it 'destroys the course' do
        course
        course_id = course.id
        ManageCourseService.new(payload: { id: course.id }).destroy
        expect { Course.find(course_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'destroys the associated chapters' do
        course = create(:course, :with_chapters, chapters_count: 3)
        course_id = course.id
        chapter_ids = course.chapters.map(&:id)
        ManageCourseService.new(payload: { id: course.id }).destroy
        chapter_ids.each do |chapter_id|
          expect { Chapter.find(chapter_id) }.to raise_error(ActiveRecord::RecordNotFound)
        end
        expect { Course.find(course_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'destroys the associated chapters and units' do
        course_with_chapters_and_units = create(:course, :with_chapters_and_units, chapters_count: 1, units_count: 2)
        course_id = course_with_chapters_and_units.id
        chapter_ids = course_with_chapters_and_units.chapters.map(&:id)
        unit_ids = course_with_chapters_and_units.chapters.flat_map(&:units).map(&:id)
        ManageCourseService.new(payload: { id: course_with_chapters_and_units.id }).destroy
        chapter_ids.each do |chapter_id|
          expect { Chapter.find(chapter_id) }.to raise_error(ActiveRecord::RecordNotFound)
        end
        unit_ids.each do |unit_id|
          expect { Unit.find(unit_id) }.to raise_error(ActiveRecord::RecordNotFound)
        end
        expect { Course.find(course_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the course does not exist' do
      it 'raises an error' do
        service = ManageCourseService.new(payload: { id: -1 })
        expect { service.destroy }.to raise_error(ManageCourseService::Error)
      end
    end
  end
end
