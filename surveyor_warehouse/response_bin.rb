require 'surveyor_warehouse/response_row'

module SurveyorWarehouse
  class ResponseBin < Struct.new(:key, :access_code, :response_group)
    def <<(response)
      q = response.question
      q.extend(SurveyorWarehouse::SurveyorExtensions::Question)
      if q.valid_data_export_identifier?
        (@responses ||= []) << response
      else
        puts "Ignoring response with data_export_identifier: #{q.data_export_identifier}"
      end
      self
    end

    def responses
      (@responses || []).dup.freeze
    end

    ##
    # Groups responses into "bins" using the 'access_code.response_group' as
    # the bin key.
    #
    # See below for an example how the binning behavior works:
    # 
    #   responses = []
    #   responses.push( 
    #     [Response access_code:'abc' response_group:0 string_value:'Jeff'],
    #     [Response access_code:'abc' response_group:0 string_value:'Bezos'],
    #     [Response access_code:'xyz' response_group:0 string_value:'Kindle'],
    #     [Response access_code:'xyz' response_group:1 string_value:'EC2'])
    #
    #   ResponseBinner.new(responses).bins # => Results in the three bins below
    #
    #   [ResponseBin key:'abc:0' responses: [
    #       [Response access_code:'abc' response_group:0 string_value:'Jeff'],
    #       [Response access_code:'abc' response_group:0 string_value:'Bezos']]
    #   [ResponseBin key:'xyz:0' responses: [
    #       [Response access_code:'xyz' response_group:0 string_value:'Kindle']]
    #   [ResponseBin key:'xyz:1' responses: [
    #       [Response access_code:'xyz' response_group:1 string_value:'EC2']]
    DEFAULT_RESPONSE_GROUP = 1
    def self.bins(responses)
      bins = {}
      responses.each do |r|
        ac = r.response_set.access_code
        rg = r.response_group || DEFAULT_RESPONSE_GROUP
        key = "#{ac}.#{rg}"
        bin = bins[key] || ResponseBin.new(key, ac, rg)
        bin << r
        bins.merge!(key => bin)
      end
      bins.values
    end

    def rows
      rows = {}
      @responses.each do |r|
        table_name = r.question.data_export_identifier.split('.')[0]
        table = rows[table_name] || ResponseRow.new(table_name, key, access_code)
        table.responses << r
        rows.merge!(table_name => table)
      end
      rows.values
    end
  end
end