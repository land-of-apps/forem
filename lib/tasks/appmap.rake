APPMAP_BASE_BRANCH = "remotes/origin/main".freeze

# rubocop:disable Metrics/BlockLength
# rubocop:disable Rails/RakeEnvironment
namespace :appmap do
  def swagger_tasks
    AppMap::Swagger::RakeTask.new.tap do |task|
      task.project_name = "Forem Server API"
      task.project_version = ["generated", `git rev-parse --short HEAD`.strip].join("-")
    end

    AppMap::Swagger::RakeDiffTask.new(:"swagger:diff", %i[base swagger_file]).tap do |task|
      task.base = APPMAP_BASE_BRANCH
    end

    task :"swagger:uptodate" do
      swagger_diff = `git diff swagger/openapi_stable.yaml`
      if swagger_diff != ""
        warn "swagger/openapi_stable.yaml has been modified:"
        warn swagger_diff
        warn "Bring it up to date with the command rake appmap:swagger"
        exit 1
      end
    end
  end

  def depends_tasks
    require "appmap_depends"

    namespace :depends do
      task :modified do
        @appmap_modified_files = AppMap::Depends.modified
        AppMap::Depends.report_list "Out of date", @appmap_modified_files
      end

      task :diff do
        @appmap_modified_files = AppMap::Depends.diff
        AppMap::Depends.report_list "Out of date", @appmap_modified_files
      end

      task :test_file_report do
        @appmap_test_file_report = AppMap::Depends.inspect_test_files
        @appmap_test_file_report.report
      end
    end

    task :test_depends do
      if @appmap_test_file_report
        @appmap_test_file_report.clean_appmaps
        @appmap_modified_files += @appmap_test_file_report.modified_files
      end

      if @appmap_modified_files.blank?
        warn "AppMaps are up to date"
        next
      end

      start_time = Time.current
      succeeded = nil
      AppMap::Depends.run_tests(@appmap_modified_files) do |test_files|
        require "shellwords"
        file_list = test_files.map(&:shellescape).join(" ")
        succeeded = true if system({ "RAILS_ENV" => "test", "APPMAP" => "true" },
          "bundle exec rspec --format documentation -t '~empty' -t '~large' -t '~unstable' #{file_list}")
      end
      if succeeded
        warn "Tests succeeded - removing out of date AppMaps."
        removed = AppMap::Depends.remove_out_of_date_appmaps(start_time)
        warn "Removed out of date AppMaps: #{removed.join(' ')}" unless removed.empty?
      end
    end

    desc "Bring AppMaps up to date with local file modifications, and updated derived data such as Swagger files"
    task modified: %i[depends:modified depends:test_file_report test_depends swagger]

    # TODO: add :swagger, :"swagger:uptodate"
    desc "Bring AppMaps up to date with file modifications relative to the base branch"
    task :diff, %i[base] => %i[depends:diff test_depends]
  end

  if %w[test development].member?(Rails.env)
    swagger_tasks
    depends_tasks
  end
end
# rubocop:enable Metrics/BlockLength
# rubocop:enable Rails/RakeEnvironment

if %w[test development].member?(Rails.env)
  desc "Bring AppMaps up to date with local file modifications, and updated derived data such as Swagger files"
  task appmap: :"appmap:modified"
end
