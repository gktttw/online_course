FactoryBot.define do
  factory :course do
    name { Faker::Educator.subject }
    lecturer_name { Faker::Name.name }
    description { Faker::Lorem.sentence }

    trait :with_chapters do
      transient do
        chapters_count { 2 }
      end

      after(:create) do |course, evaluator|
        create_list(:chapter, evaluator.chapters_count, course: course)
      end
    end

    trait :with_chapters_and_units do
      transient do
        chapters_count { 3 }
        units_count { 2 }
      end

      after(:create) do |course, evaluator|
        create_list(:chapter, evaluator.chapters_count, :with_units, units_count: evaluator.units_count, course: course)
      end
    end
  end
end
