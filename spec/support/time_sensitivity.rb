RSpec.configure do |config|
  config.around(:example, :time_sensitive) do |example|
    Timecop.freeze do
      example.run
    end
  end
end
