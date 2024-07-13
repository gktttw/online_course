require 'rails_helper'

RSpec.describe "Api::V1::CoursesControllers", type: :request do
  describe "GET /index" do
    it "returns http success" do
      expect_any_instance_of(ManageCourseService).to receive(:get_all).and_return([])
      get "/api/v1/courses"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    let(:target_course) {
      FactoryBot.create(:course)
    }
    context "when course exists" do
      it "returns http success" do
        expect_any_instance_of(ManageCourseService).to receive(:show_one).and_return(target_course.to_json_with_associations)
        get "/api/v1/courses/#{target_course.id}"
        expect(response).to have_http_status(:success)
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["id"]).to eq(target_course.id)
      end
    end

    context "when course does not exist" do
      it "returns http not found" do
        expect_any_instance_of(ManageCourseService).to receive(:show_one).and_raise(
          ManageCourseService::Error.new("cannot find curse id: -1", :not_found)
        )
        get "/api/v1/courses/-1"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /create" do
    context "when create success" do
      it "returns http success" do
        expect_any_instance_of(ManageCourseService).to receive(:create).and_return({})
        post "/api/v1/courses/", params: {
          course: {
            name: 'my_new_course',
            lecturer_name: 'asdf',
          }
        }
        expect(response).to have_http_status(:success)
      end
    end
    context "when create not success" do
      it "returns http error" do
        expect_any_instance_of(ManageCourseService).to receive(:create).and_raise(
          ManageCourseService::Error.new("some err", :internal_server_error)
        )
        post "/api/v1/courses/", params: {
          course: {
            name: 'my_new_course',
            lecturer_name: 'asdf',
            asdf: 'asdf'
          }
        }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end

  describe "GET /update" do
    context "when update success" do
      it "returns http success" do
        expect_any_instance_of(ManageCourseService).to receive(:update).and_return({})
        patch "/api/v1/courses/1", params: {
          course: {
            name: 'my_new_course',
            lecturer_name: 'asdf',
          }
        }
        expect(response).to have_http_status(:success)
      end
    end
    context "when update not success" do
      it "returns http error" do
        expect_any_instance_of(ManageCourseService).to receive(:update).and_raise(
          ManageCourseService::Error.new("some err", :internal_server_error)
        )
        patch "/api/v1/courses/1", params: {
          course: {
            name: 'my_new_course',
            lecturer_name: 'asdf',
            asdf: 'asdf'
          }
        }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end

  describe "GET /destroy" do
    context "when destroy success" do
      it "returns http success" do
        expect_any_instance_of(ManageCourseService).to receive(:destroy).and_return({})
        delete "/api/v1/courses/1"
        expect(response).to have_http_status(:success)
      end
    end
    context "when destroy not success" do
      it "returns http error" do
        expect_any_instance_of(ManageCourseService).to receive(:destroy).and_raise(
          ManageCourseService::Error.new("some err", :internal_server_error)
        )
        delete "/api/v1/courses/1"
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
