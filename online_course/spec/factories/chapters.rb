FactoryBot.define do
  factory :chapter do
    name { Faker::Educator.course_name }
    ordering { Faker::Number.between(from: 1, to: 50) }
    course

    trait :with_units do
      transient do
        units_count { 2 }
      end

      after(:create) do |chapter, evaluator|
        create_list(:unit, evaluator.units_count, chapter: chapter)
      end
    end
  end
end
