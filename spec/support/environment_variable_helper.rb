module EnvironmentVariableHelper
  SIXERS = %w[
    Purus
    Cras
    Ipsum
  ].freeze

  SEVEN_DAYS = %w[
    Porta
    Ornare
    Ullamcorper
  ].freeze

  CASH_PRIZES = %w[
    Consectetur
    Mattis
    Adipiscing
  ].freeze

  TITLES = %w[
    Ultricies
    Sollicitudin
    Tellus
  ].freeze

  def with_env(options, &)
    ClimateControl.modify(options, &)
  end
end

RSpec.configure do |config|
  config.include EnvironmentVariableHelper
  config.around do |example|
    envs = {
      "SIXERS" => EnvironmentVariableHelper::SIXERS.join("|"),
      "SEVEN_DAYS" => EnvironmentVariableHelper::SEVEN_DAYS.join("|"),
      "CASH_PRIZES" => EnvironmentVariableHelper::CASH_PRIZES.join("|"),
      "TITLES" => EnvironmentVariableHelper::TITLES.join("|"),
    }

    with_env(envs) do
      example.run
    end
  end
end
