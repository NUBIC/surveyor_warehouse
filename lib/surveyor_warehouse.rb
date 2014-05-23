require 'surveyor'
require 'surveyor_warehouse/normalized_survey_structure'
require 'surveyor_warehouse/response_bin'
require 'surveyor_warehouse/response_row'
require 'surveyor_warehouse/railtie' if defined?(Rails)

module SurveyorWarehouse
  module SurveyorExtensions
    module Survey
      def current_versions
        group = ::Survey.order("created_at DESC, survey_version DESC").all.group_by(&:access_code)
        group.map { |access_code, surveys|  surveys.first }
      end
    end
    module Question
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


module SurveyorWarehouse
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.transform
    Survey.extend(SurveyorWarehouse::SurveyorExtensions::Survey)

    surveys = Survey.current_versions

    surveys.each do |s|
      ns = NormalizedSurveyStructure.new(s)
      ns.create!
      s.response_sets.each do |rs|
        # logger.debug("Transforming [ResponseSet id:#{rs.id}] for [Survey id:#{s.id} title:'#{s.title}")
        bins = ResponseBin.bins(rs.responses)
        bins.map(&:rows).flatten.each(&:insert!)
        logger.info("Transformed [ResponseSet id:#{rs.id}] for [Survey id:#{s.id} title:'#{s.title}']")
      end
    end
  end

  def self.clobber
    Survey.extend(SurveyorWarehouse::SurveyorExtensions::Survey)

    surveys = Survey.current_versions

    surveys.map(&:response_sets).flatten.each do |rs|
      ns = NormalizedSurveyStructure.new(rs.survey)
      ns.destroy!
    end

  end
end