namespace :partition do
  # Define a task that accepts an argument
  desc "Partition tests by index"
  task :tests, [:index, :total, :filename] do |task, args|
    raise "Must provide index and total" unless args[:index] && args[:total]

    index = args[:index].to_i
    total = args[:total].to_i

    test_files = Dir["spec/**/*_spec.rb"].
      sort.
      select.
      with_index do |el, i|
        i % total == index
      end
    
    if args[:filename]
      File.write(args[:filename], test_files.join("\n"))
    else
      puts test_files.join("\n")
    end
  end
end
