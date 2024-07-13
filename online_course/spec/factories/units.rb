FactoryBot.define do
  factory :unit do
    name { Faker::Educator.course_name }
    description { Faker::Lorem.sentence }
    content { Faker::Lorem.sentence }
    ordering { Faker::Number.between(from: 1, to: 50) }
    chapter
  end
end
