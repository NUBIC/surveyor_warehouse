require 'surveyor_warehouse'

namespace :surveyor do
  desc 'Transforms the survey response sets into the defined warehouse form'
  task :warehouse => [:environment, :clobber] do
    SurveyorWarehouse.transform
  end

  desc 'Clobber the warehouse'
  task :clobber do
    SurveyorWarehouse.clobber
  end
end