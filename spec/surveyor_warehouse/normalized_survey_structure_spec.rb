require 'spec_helper'
require 'surveyor_warehouse'

describe SurveyorWarehouse::NormalizedSurveyStructure do
  let(:survey) do
    Surveyor::Parser.new.parse( 
      <<-SURVEY
        survey "Favorites" do
          section "One" do
            q "What is your favorite name?", :data_export_identifier => 'favorites.name'
            a :string

            q "What is your favorite color?", :pick => :one, :data_export_identifier => 'favorites.color'
            a "red"
            a "blue"
            
            q "Choose the colors you don't like", :pick => :any, :data_export_identifier => 'hated.colors'
            a "red"
            a "blue"
            a "green"
            
          end
        end
      SURVEY
    )
  end

  let(:normalized) { SurveyorWarehouse::NormalizedSurveyStructure.new(survey) }

  let(:connection) do
    ActiveRecord::Base.connection
  end

  def drop_tables(*tables)
    tables.each do |t|
      connection.drop_table(t) if connection.table_exists?(t)
    end
  end

  describe '#create!' do
    after(:each) do
      drop_tables(:favorites, :hated)
    end

    it 'creates tables with scalar types' do
      normalized.create!
      connection.table_exists?(:favorites).should be(true)
      columns = connection.columns(:favorites).map{ |c| [c.name, c.sql_type] }.sort
      columns.should == [
        %w(access_code text),
        %w(color text),
        %w(id text),
        %w(name text)
      ]
    end

    it 'creates tables with array types' do
      normalized.create!
      connection.table_exists?(:hated).should be(true)
      columns = connection.columns(:hated).map(&:name).sort
      columns.should == %w(access_code colors id)
    end
  end

  describe '#destroy!' do
    before(:each) do
      connection.create_table(:foo) do |t|
        t.integer :id
      end
    end

    after(:each) do
      drop_tables(:favorites, :hated, :foo)
    end

    it "drops all normalized tables" do
      normalized.create!
      normalized.destroy!
      connection.table_exists?(:favorites).should be(false)
      connection.table_exists?(:hated).should be(false)
      connection.table_exists?(:foo).should be(true)
    end
  end

  describe '#tables' do
    let (:tables) { normalized.tables }
    let (:columns) { tables.inject({}){ |accum, t| accum.merge(t.name => t.columns) } }

    it 'has tables from data export identifiers' do
      tables.map(&:name).sort.should == %w(favorites hated)
    end

    it 'has columns with scalar types' do
      columns['favorites'].map { |col| [col.name, col.type] }.sort.should == [
        ['access_code', 'text'],
        ['color', 'text'],
        ['id', 'text'],
        ['name', 'text']        
      ]
    end

    it 'has columns with array types' do
      columns['hated'].map { |col| [col.name, col.type] }.sort.should == [
        ['access_code', 'text'],
        ['colors', 'text[]'],
        ['id', 'text']
      ]
    end

    it 'ignores questions without a data export identifier' do
      blank_survey = Surveyor::Parser.new.parse(
        <<-SURVEY
          survey "Pet" do
            section "Name" do
              q "What is your pet's name?"
              a :string
            end
          end
        SURVEY
      )

      norm = SurveyorWarehouse::NormalizedSurveyStructure.new(blank_survey)

      expect(norm.tables).to eq([])
    end

    it 'ignores questions with an incomplete data export identifier' do
      odd_survey = Surveyor::Parser.new.parse(
        <<-SURVEY
          survey "Pet" do
            section "Name" do
              q "What is your pet's name?", :data_export_identifier => 'pet'
              a :string
            end
          end
        SURVEY
      )

      norm = SurveyorWarehouse::NormalizedSurveyStructure.new(odd_survey)

      expect(norm.tables).to eq([])
    end
  end
end