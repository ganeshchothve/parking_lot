FactoryBot.define do
 factory :asset do
   file Rack::Test::UploadedFile.new(File.open(File.join(Rails.root, "/spec/test_files/correct_csv.csv")))
 end

 %w[correct_csv empty_file incorrect_header invalid_file_1 invalid_file_2 repeat_file].each do |_file|
    factory _file, parent: :user do
      file Rack::Test::UploadedFile.new(File.open(File.join(Rails.root, "/spec/test_files/" + _file + ".csv")))
    end
  end
end