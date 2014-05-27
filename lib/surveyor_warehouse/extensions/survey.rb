require 'active_support/concern'

module SurveyorWarehouse
  module Extensions
    module Survey
      extend ActiveSupport::Concern
      module ClassMethods
        def current_versions
          group = ::Survey.order("created_at DESC, survey_version DESC").all.group_by(&:access_code)
          group.map { |access_code, surveys|  surveys.first }
        end
      end
    end
  end
end