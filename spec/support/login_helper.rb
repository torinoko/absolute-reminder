# frozen_string_literal: true

module LoginHelper
  def log_in_as(user)
    allow_any_instance_of(ApplicationController)
      .to receive(:current_user).and_return(user)
  end
end

RSpec.configure do |config|
  config.include LoginHelper, type: :request
end
