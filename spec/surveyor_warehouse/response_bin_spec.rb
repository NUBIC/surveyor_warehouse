require 'spec_helper'

describe 'SurveyorWarehouse::ResponseBin' do
  let(:color)   { Question.new(:data_export_identifier => 'favorite.color') }
  let(:food)    { Question.new(:data_export_identifier => 'favorite.food') }
  let(:utencil) { Question.new(:data_export_identifier => 'hated.utencil') }
  let(:tree)    { Question.new(:data_export_identifier => 'meh.tree') }

  def r(q)
    Response.new(:question => q)
  end

  describe '#tables' do
   let(:bin) { SurveyorWarehouse::ResponseBin.new.tap{ |bin| bin << r(color) << r(food) << r(utencil) << r(tree) } }

    it 'groups into tables' do
      bin.rows.map(&:name).sort.should == [:favorite, :hated, :meh]
    end    
  end

  describe '::bins' do
    let(:rs_abc) { ResponseSet.new.tap { |r| r.access_code = 'abc' } }
    let(:rs_def) { ResponseSet.new.tap { |r| r.access_code = 'def' } }

    let(:r0) { Response.new(:response_set => rs_abc, :question => food) }
    let(:r1) { Response.new(:response_set => rs_abc, :question => utencil) }
    let(:r2) { Response.new(:response_set => rs_def, :question => food) }
    let(:r3) { Response.new(:response_set => rs_def, :question => utencil, :response_group => 2) }

    let(:responses) { [r0, r1, r2, r3] }

    it 'should bin each access_code and response_group combination' do
      bins = SurveyorWarehouse::ResponseBin.bins(responses)
      bins.map(&:key).sort.should == %w(abc.1 def.1 def.2)
      bins.map(&:access_code).sort.should == %w(abc def def)
    end

    it 'should ignore responses with invalid data export identifiers' do
      bad_1 = Question.new(:data_export_identifier => '')
      bad_2 = Question.new(:data_export_identifier => 'tree')

      Response.new(:response_set => rs_abc)
    end
  end
end