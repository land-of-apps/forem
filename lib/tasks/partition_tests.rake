namespace :partition do
  # Define a task that accepts an argument
  desc "Run tests partitioned by index"
  task :test, %i[index total] => :environment do |_task, args|
    raise "Must provide index and total" unless args[:index] && args[:total]

    index = args[:index].to_i
    total = args[:total].to_i

    $LOAD_PATH.unshift "lib"
    $LOAD_PATH.unshift "test"

    Dir["test/**/*_test.rb"].select.with_index { |_el, i| i % total == index }.each do |test_file|
      load test_file
    end
  end
end
