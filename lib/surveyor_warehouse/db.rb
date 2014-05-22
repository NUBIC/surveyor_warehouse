module SurveyorWarehouse
  module DB
    def self.connection
      @connection ||= Sequel.connect(
          :adapter=> adapter, 
          :host=>'localhost', 
          :database=> database, 
          :user=> username, 
          :password=> password).extension(:pg_array)
      @connection.extend(SequelExtension::Connection)
    end

    def self.configurations
      @configurations ||= ::ActiveRecord::Base.configurations[Rails.env]
    end

    def self.username
      @username ||= configurations['username']
    end
    
    def self.password
      @password ||= configurations['password']
    end
    
    def self.database
      @database ||= configurations['database']
    end

    def self.adapter
      @adapter ||=
        if 'postgresql' == configurations['adapter']
          'postgres'
        else
          raise "Unsupported database adapter: #{db['adapter']}"
        end
    end

    ##
    # Columns are returned a hash like below:
    #
    # { :column1 => [:primary_key], :column2 => [:not_null] }
    def self.columns(tablename)
      connection.schema(tablename.to_sym).inject({}) do |attrs, (cname, cattrs)| 
        attrs.merge(cname => cattrs)
      end
    end
  end

  module SequelExtension
    module Connection
      def columns(tablename)
        self.schema(tablename.to_sym).inject({}) do |attrs, (cname, cattrs)| 
          attrs.merge(cname => cattrs)
        end
      end
    end
  end
end