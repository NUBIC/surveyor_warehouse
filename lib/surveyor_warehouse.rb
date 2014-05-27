require 'surveyor'
require 'active_support/concern'

require 'surveyor_warehouse/normalized_survey_structure'
require 'surveyor_warehouse/response_bin'
require 'surveyor_warehouse/response_row'
require 'surveyor_warehouse/railtie' if defined?(Rails)
require 'surveyor_warehouse/extensions/question'
require 'surveyor_warehouse/extensions/survey'

module SurveyorWarehouse
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.transform
    Survey.send(:include, SurveyorWarehouse::Extensions::Survey)

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
    Survey.send(:include, SurveyorWarehouse::Extensions::Survey)

    surveys = Survey.current_versions

    surveys.map(&:response_sets).flatten.each do |rs|
      ns = NormalizedSurveyStructure.new(rs.survey)
      ns.destroy!
    end

  end
end

# Survey.send(:include, SurveyorWarehouse::Extensions::Survey)
# Question.send(:include, SurveyorWarehouse::Extensions::Question)