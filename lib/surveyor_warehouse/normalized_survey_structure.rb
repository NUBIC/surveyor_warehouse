require 'surveyor_warehouse/db'

module SurveyorWarehouse
  class NormalizedSurveyStructure
    def initialize(survey)
      @survey = survey
    end

    ##
    # response_classes
    def tables
      questions = @survey.sections_with_questions.map(&:questions).flatten
      Question.send(:include, SurveyorWarehouse::Extensions::Question)
      predefs = questions.select {|q| q.valid_data_export_identifier? }.map do |question| 
        dei_tokens = question.data_export_identifier.split('.')

        table = dei_tokens[0]
        column = dei_tokens[1]
        type = database_type(question)
          
        [table, column, type]
      end

      tables = {}
      predefs.each do |d|
        table_name, column_name, column_type = d
        table = tables[table_name] || TableDefinition.new(table_name)
        table.columns << ColumnDefinition.new(column_name, column_type)
        tables.merge!(table_name => table)
      end

      # Add primary key and response set access code columns
      tables.each do |name, tdef|
        tdef.columns << ColumnDefinition.new('access_code', 'text')
        tdef.columns << ColumnDefinition.new('id', 'text')
      end

      @tables ||= tables.values
    end

    def ddl
      tables.create!
    end

    ##
    # Force creates the structure by destroying all the tables first
    #
    def create!
      destroy!
      tables.each(&:create)
    end

    ##
    # Destroy all the tables defined in the survey data_export_identifiers
    #
    def destroy!
      drop_ddl = tables.map(&:name).map do |t|
        "drop table if exists #{t};\n"
      end.join
      ActiveRecord::Base.connection.execute(drop_ddl)
    end

    private
    SUPPORTED_TYPES = %w(date datetime decimal float integer string text)
    def database_type(question)
      case question.pick
      when 'none'
        response_classes = question.answers.map(&:response_class).uniq
        raise "Muliple answer types are unsupported: #{response_classes.join(', ')}" if response_classes.size > 1
        type = response_classes[0].tap do |t|
          raise "Unsupported column type '#{t}' for question: #{question.inspect}}" unless SUPPORTED_TYPES.include?(t)
        end
        type == 'string' ? 'text' : type
      when 'one'
        'text'
      when 'any'
        "text[]"
      else
        raise "Unable to find type for question: #{question.inspect}"
      end
    end

    class TableDefinition < Struct.new(:name)
      def columns
        @columns ||= []
      end

      def create
        ActiveRecord::Base.connection.create_table(name.to_sym, :id => false) do |t|
          columns.each do |c|
            t.column c.name, c.type
          end
        end
      end
    end

    class ColumnDefinition < Struct.new(:name, :type)
    end
  end
end