require 'spec_helper'

describe 'SurveyorWarehouse::ResponseRow' do
  let(:connection) do
    SurveyorWarehouse::DB.connection
  end

  let(:favorites) { connection[:favorites] }
  let(:hated) { connection[:hated] }

  before(:each) do
    connection.create_table!(:favorites) do
      primary_key :id, String
      String :access_code
      String :name
      Integer :color
    end
    connection.extension :pg_array
    Sequel::Model.db.extension :pg_array
    connection.create_table!(:hated) do
      primary_key :id, String
      String :access_code
      column :colors, 'integer[]'
    end
  end

  describe '#insert!' do
    let (:fav_color) do
      Question.new(:text => 'favorite color?', :pick => :one, :data_export_identifier => 'favorites.color').
        tap {|q| q.answers = [
          Answer.new(:text => 'red', :reference_identifier => 3),
          Answer.new(:text => 'green', :reference_identifier => 5),
          Answer.new(:text => 'blue', :reference_identifier => 7)]}
    end

    let (:fav_name) do
      Question.new(:text => 'favorite name?', :data_export_identifier => 'favorites.name').
        tap { |q| q.answers = [
          Answer.new(:response_class => 'string')]}
    end

    let (:hated_colors) do
      Question.new(:text => 'hated colors?', :pick => :any, :data_export_identifier => 'hated.colors').
        tap {|q| q.answers = [
          Answer.new(:text => 'brown', :reference_identifier => 2),
          Answer.new(:text => 'orange', :reference_identifier => 4),
          Answer.new(:text => 'urkel', :reference_identifier => 6)]}
    end

    it 'inserts string data' do
      r = Response.new(:question => fav_name, :answer => fav_name.answers[0], :string_value => 'homer')
      row = SurveyorWarehouse::ResponseRow.new('favorites', 'abc.1', 'abc')
      row.responses << r
      row.insert!

      favorites.map(:name).should == ['homer']
    end

    it 'inserts integer data' do
      r = Response.new(:question => fav_color, :answer => fav_color.answers[1])
      row = SurveyorWarehouse::ResponseRow.new('favorites', 'abc.1', 'abc')
      row.responses << r
      row.insert!
      
      favorites.map(:color).should == [5]
    end

    it 'inserts array data' do
      r0 = Response.new(:question => hated_colors, :answer => hated_colors.answers[1])
      r1 = Response.new(:question => hated_colors, :answer => hated_colors.answers[2])
      row = SurveyorWarehouse::ResponseRow.new('hated', 'abc.1', 'abc')
      row.responses << r0 << r1
      row.insert!

      hated.map(:colors).sort.should == [[4,6]]
    end
  end
end