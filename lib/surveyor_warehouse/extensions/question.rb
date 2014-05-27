require 'active_support/concern'

module SurveyorWarehouse
  module Extensions
    module Question
      extend ActiveSupport::Concern
      included do
        ##
        # A question's data_export_identifier should follow the
        # format 'table.column' (e.g. 'patients.name')
        def valid_data_export_identifier?
          dei = self.try(:data_export_identifier)
          dei.present? && dei.split('.').size == 2
        end
      end
    end
  end
end
