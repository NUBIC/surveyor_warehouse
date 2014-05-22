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
      definitions = questions.select {|q| q.data_export_identifier.present? && q.data_export_identifier.split('.').size == 2 }.map do |question| 
        dei_tokens = question.data_export_identifier.split('.')

        table = dei_tokens[0]
        column = dei_tokens[1]
        type = 
          case question.pick
          when 'none'
            response_classes = question.answers.map(&:response_class).uniq
            raise "Muliple answer types are unsupported: #{response_classes}" if response_classes.size > 1
            case response_classes[0]
            when 'string'
              'string'
            when 'text'
              'text'
            when 'date'
              'date'
            when 'datetime'
              'datetime'
            when 'float'
              'float'
            when 'decimal'
              'decimal'
            else
              raise "Unable to find type for question: #{question.inspect}"
            end
          when 'one'
            'text'
          when 'any'
            "text[]"
          else
            raise "Unable to find type for question: #{question.inspect}"
          end

        [table, column, type]
      end

      tables = {}
      definitions.each do |d|
        table_name, column_name, column_type = d
        table = tables[table_name] || TableDefinition.new(table_name)
        table.columns << ColumnDefinition.new(column_name, column_type)
        tables.merge!(table_name => table)
      end

      # Add primary key and response set access code columns
      tables.each do |name, tdef|
        tdef.columns << ColumnDefinition.new('access_code', 'string')
        tdef.columns << ColumnDefinition.new('id', 'string')
      end

      @tables ||= tables.values
    end

    def ddl
      tables.create!
    end

    def create!
      destroy!
      tables.each(&:create)
    end

    def destroy!
      drop_ddl = tables.map(&:name).map do |t|
        "drop table if exists #{t};\n"
      end.join
      ActiveRecord::Base.connection.execute(drop_ddl)
    end

    class TableDefinition < Struct.new(:name)
      def columns
        @columns ||= []
      end

      def create
        # mDB = SurveyorWarehouse::DB.connection

        # ctx = binding
        # mDB.create_table(name.to_sym) do
        #   # Cannot use colummns directly because it is overwritten inside
        #   # this block by #create_table
        #   eval("columns", ctx).each do |c|
        #     column c.name, c.type
        #   end
        # end
        ActiveRecord::Base.connection.create_table(name.to_sym) do |t|
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