module Api
  module V1
    class CoursesController < ApplicationController

      """
      example of request body:
      {
        course: {
          name: 'my_new_course',
          lecturer_name: 'my_lecturer_name',
          chapters_attributes: [
            {
              name: 'Chapter 1',
              units_attributes: [
                {
                  name: 'unit 1-1',
                  content: 'unit 1-1 content'
                },
                {
                  name: 'unit 1-2',
                  content: 'unit 1-2 content'
                }
              ]
            },
            {
              name: 'Chapter 2',
              units_attributes: [
                {
                  name: 'unit 2-1',
                  content: 'unit 2-1 content'
                },
                {
                  name: 'unit 2-2',
                  content: 'unit 2-2 content'
                },
                {
                  name: 'unit 2-3',
                  content: 'unit 2-3 content'
                }
              ]
            }
          ]
        }
      }
      """
      def create
        res = ManageCourseService.new(payload: create_courses_params.to_h).create
        render json: res, status: :created
      rescue ManageCourseService::Error => e
        render json: { error: e.message }, status: e.render_status
      end

      def index
        # TODO: add pagination cursor based
        res = ManageCourseService.new.get_all
        render json: res, status: :ok
      end

      def show
        res = ManageCourseService.new(payload: {id: params[:id]}).show_one
        render json: res, status: :ok
      rescue ManageCourseService::Error => e
        render json: { error: e.message }, status: e.render_status
      end

      def destroy
        res = ManageCourseService.new(payload: {id: params[:id]}).destroy
        render json: res, status: :ok
      rescue ManageCourseService::Error => e
        render json: { error: e.message }, status: e.render_status
      end

      def update
        res = ManageCourseService.new(payload: update_courses_params.to_h.merge(id: params[:id])).update
        render json: res, status: :ok
      rescue ManageCourseService::Error => e
        render json: { error: e.message }, status: e.render_status
      end

      private

      def create_courses_params
        params.require(:course).permit(
          :name, :lecturer_name,
          chapters_attributes: [
            :name, :description,
            units_attributes: [:name, :content]
          ]
        )
      end

      def update_courses_params
        params.require(:course).permit(
          :name, :lecturer_name, :description, :id,
          chapters_attributes: [
            :name, :description, :id, :ordering,
            units_attributes: [:name, :content, :id, :ordering, :description]
          ]
        )
      end
    end
  end
end
