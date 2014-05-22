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
      String :color
    end
    connection.extension :pg_array
    Sequel::Model.db.extension :pg_array
    connection.create_table!(:hated) do
      primary_key :id, String
      String :access_code
      column :colors, 'text[]'
    end
  end

  describe '#insert!' do
    let(:survey) do 
      Surveyor::Parser.new.parse(<<-SURVEY
        survey "Favorites" do
          section "One" do
            q "What is your favorite name?", :data_export_identifier => 'favorites.name'
            a :string

            q "What is your favorite color?", :pick => :one, :data_export_identifier => 'favorites.color'
            a_3 "red"
            a_5 "green"
            a_7 "blue"
            
            q "Choose the colors you don't like", :pick => :any, :data_export_identifier => 'hated.colors'
            a_2 "red"
            a_4 "blue"
            a_6 "green"
            
          end
        end
        SURVEY
      )
    end

    def find_question_by_dei(dei)
        questions = survey.sections.map(&:questions).flatten.select { |q| q.data_export_identifier == dei}

      if questions.size == 1
        questions.first
      elsif questions.size > 1
        raise "Too many questions found with dei: #{dei}"
      else
        raise "No questions found with dei: #{dei}"
      end        
    end

    def find_answer_by_refid(q, refid)
      answers = q.answers.select { |a| a.reference_identifier == refid}

      if answers.size == 1
        answers.first
      elsif answers.size > 1
        raise "Too many answers found with refid: #{refid}"
      else
        raise "No answers found with refid: #{refid}"
      end 
    end

    let (:fav_color) { find_question_by_dei('favorites.color') }
    let (:fav_name) { find_question_by_dei('favorites.name') }
    let (:hated_colors) { find_question_by_dei('hated.colors') }

    it 'inserts string data' do
      r = Response.new(:question => fav_name, :answer => fav_name.answers[0], :string_value => 'homer')
      row = SurveyorWarehouse::ResponseRow.new('favorites', 'abc.1', 'abc')
      row.responses << r
      row.insert!

      favorites.map(:name).should == ['homer']
    end

    it 'inserts integer data' do
      r = Response.new(:question => fav_color, :answer => find_answer_by_refid(fav_color, '5'))
      row = SurveyorWarehouse::ResponseRow.new('favorites', 'abc.1', 'abc')
      row.responses << r
      row.insert!
      
      favorites.map(:color).should == ['5']
    end

    it 'inserts array data' do
      r0 = Response.new(:question => hated_colors, :answer => find_answer_by_refid(hated_colors, '4'))
      r1 = Response.new(:question => hated_colors, :answer => find_answer_by_refid(hated_colors, '6'))
      row = SurveyorWarehouse::ResponseRow.new('hated', 'abc.1', 'abc')
      row.responses << r0 << r1
      row.insert!

      hated.map(:colors).sort.should == [%w(4 6)]
    end
  end
end