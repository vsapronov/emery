task default: %w[test]

task :test do
  ruby "-Ilib:test test/*_test.rb --runner=junitxml --junitxml-output-file=/tmp/test-results/out_report.xml"
end