class ManageCourseService
  def initialize(payload: {})
    @params = payload
  end

  def get_all
    courses = Course.includes(chapters: :units).all
    courses.to_json(include: { chapters: { include: :units } })
  end

  def show_one
    course = Course.find_by!(id: @params[:id])
    course.to_json_with_associations
  rescue ActiveRecord::RecordNotFound
    raise Error.new("cannot find curse id: #{@params[:id]}", :not_found)
  end

  def create
    ActiveRecord::Base.transaction do
      course = Course.create!(@params.except(:chapters_attributes))
      chapter_records = []
      unit_records = []

      @params[:chapters_attributes]&.each_with_index do |chapter_attr, chapter_ordering|
        chapter = course.chapters.new(chapter_attr.except(:units_attributes).merge(ordering: chapter_ordering))
        chapter_records << chapter

        chapter_attr[:units_attributes]&.each_with_index do |unit_attr, unit_ordering|
          unit_records << chapter.units.new(unit_attr.merge(ordering: unit_ordering))
        end
      end

      Chapter.import! chapter_records
      Unit.import! unit_records

      course.to_json_with_associations
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.take(20).join("\n"))
      raise Error.new(e.message)
    rescue => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.take(20).join("\n"))
      raise Error.new(e.message, :internal_server_error)
    end
  end

  def destroy
    course = Course.find(@params[:id])
    ActiveRecord::Base.transaction do
      course.destroy!
    end

    { message: "Course and associated records deleted successfully" }
  rescue ActiveRecord::RecordNotFound => e
    raise Error.new(e.message, :not_found)
  rescue ActiveRecord::RecordNotDestroyed => e
    raise Error.new(e.record.errors.full_messages.join(", "))
  rescue => e
    raise Error.new(e.message, :internal_server_error)
  end

  def update
    ActiveRecord::Base.transaction do
      course = Course.includes(chapters: :units).find(@params[:id])
      course.update!(@params.except(:chapters_attributes, :id))

      if @params[:chapters_attributes].nil?
        return course.to_json_with_associations
      end

      chapter_ids = @params[:chapters_attributes].map { |chap| chap[:id] }
      existing_chapters_ids = course.chapters.pluck(:id)
      missing_chapters = chapter_ids - existing_chapters_ids
      raise ActiveRecord::RecordNotFound, "Chapters not found: #{missing_chapters.join(', ')}" if missing_chapters.any?

      chapters_to_delete = []
      units_to_delete = []

      chapters_to_delete << course.chapters.reject{ |chap| chapter_ids.include? chap.id }

      existing_chapters = course.chapters.filter{ |chap| chapter_ids.include? chap.id }.index_by(&:id)

      chapter_records = []
      unit_records = []

      @params[:chapters_attributes].each do |chapter_attr|
        chapter = existing_chapters[chapter_attr[:id]] || course.chapters.new
        chapter.assign_attributes(chapter_attr.except(:units_attributes, :id))
        chapter_records << chapter

        if chapter.persisted?
          next if chapter_attr[:units_attributes].nil?
          unit_ids = chapter_attr[:units_attributes].map { |unit| unit[:id] }
          existing_units_ids = chapter.units.pluck(:id)
          missing_units = unit_ids - existing_units_ids
          raise ActiveRecord::RecordNotFound, "Units not found: #{missing_units.join(', ')}" if missing_units.any?

          units_to_delete << chapter.units.reject{ |unit| unit_ids.include? unit.id }
          existing_units = chapter.units.where(id: unit_ids).index_by(&:id)

          chapter_attr[:units_attributes].each do |unit_attr|
            unit = existing_units[unit_attr[:id]] || chapter.units.new
            unit.assign_attributes(unit_attr)
            unit_records << unit
          end
        else
          chapter_attr[:units_attributes].each do |unit_attr|
            unit_records << chapter.units.new(unit_attr)
          end
        end
      end

      Chapter.where(id: chapters_to_delete.flatten.map(&:id)).destroy_all if chapters_to_delete.flatten.any?
      Unit.where(id: units_to_delete.flatten.map(&:id)).destroy_all if units_to_delete.flatten.any?

      Chapter.import! chapter_records, on_duplicate_key_update: { conflict_target: [:id], columns: [:name, :ordering, :updated_at] }
      Chapter.import! chapter_records.filter{ !_1.persisted? }
      Unit.import! unit_records, on_duplicate_key_update: { conflict_target: [:id], columns: [:name, :content, :ordering, :description, :updated_at] }
      Unit.import! unit_records.filter{ !_1.persisted? }

      course.to_json_with_associations
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.take(20).join("\n"))
      raise Error.new(e.message)
    rescue ActiveRecord::RecordNotFound => e
      # it's when chapter or unit id does not belongs to this course, this should be forbidden
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.take(20).join("\n"))
      raise Error.new(e.message, :unprocessable_entity)
    rescue => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.take(20).join("\n"))
      raise Error.new(e.message, :internal_server_error)
    end
  end

  class Error < StandardError
    attr_reader :render_status

    def initialize(msg = "Failed to handle course and associated records", render_status = :unprocessable_entity)
      @render_status = render_status
      super(msg)
    end
  end
end
