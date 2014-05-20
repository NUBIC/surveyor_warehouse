require 'surveyor_warehouse/db'
require 'sequel'

module SurveyorWarehouse
  class ResponseRow < Struct.new(:name, :id, :access_code)
    def responses
      @responses ||= []
    end

    def name
      super.to_sym
    end

    def insert!
      column_and_values = {}
      col_and_val = @responses.map do |r|
        column = r.question.data_export_identifier.split('.')[1]

        value_field = case r.answer.response_class
          when 'datetime'; 'datetime_value'
          when 'date'; 'date_value'
          when 'time'; 'time_value'
          when 'float'; 'float_value'
          when 'integer'; 'integer_value'
          when 'string'; 'string_value'
          when 'text'; 'text_value'
          end

        value =  value_field.present? ? r.send(value_field) : r.answer.try(:reference_identifier).to_i
        [column.to_sym, value]
      end

      mDB = SurveyorWarehouse::DB.connection
      schema = mDB.schema(name.to_sym).inject({}) { |attrs, (cname, cattrs)| attrs.merge(cname => cattrs) }

      column_and_values = col_and_val.inject({}) do |accum, (col, val)|
        if schema[col][:db_type] =~ /\[\]/
          accum[col] = Sequel.pg_array((accum[col] || []) << val)
        else
          accum[col] = val
        end
        accum
      end

      column_and_values.merge!('id' => id, 'access_code' => access_code)

      ds = mDB[name]
      
      ds.insert(column_and_values)
      
    end
  end
end