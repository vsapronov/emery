task default: %w[test]

task :test do
  FileUtils.mkdir_p "./test-results"
  ruby "-Ilib:test test/*_test.rb --runner=junitxml --junitxml-output-file=./test-results/out_report.xml"
end