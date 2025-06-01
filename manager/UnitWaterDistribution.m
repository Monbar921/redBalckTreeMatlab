classdef UnitWaterDistribution < handle
    properties
        sumWaterConsumption;
        sumPower;
        selectedUnits;
    end

    methods
        function obj = UnitWaterDistribution()
            obj.resetState();
        end

        function newUnitWater = copyAndWriteDistribution(obj, unit, point, powerTask)
            newUnitWater = UnitWaterDistribution();

            for idx = 1:length(obj.selectedUnits)
                if strcmp(obj.selectedUnits(idx).getUnit().getName(), unit.getName()) || obj.sumPower >= powerTask
                    newUnitWater = {};
                    break;
                end
            end
    
            %disp(sprintf('obj.sumPower = %f, powerTask = %f', obj.sumPower , powerTask));

            if ~isempty(newUnitWater)
                newUnitWater.sumWaterConsumption = obj.sumWaterConsumption;
                newUnitWater.sumPower = obj.sumPower;
                newUnitWater.selectedUnits = obj.selectedUnits;

                newUnitWater.selectedUnits(end+1) = SelectedUnit(point.key, point.value, unit);
                newUnitWater.sumWaterConsumption = newUnitWater.sumWaterConsumption + point.value;
                newUnitWater.sumPower = newUnitWater.sumPower + point.key;
            end
        end

        function addDistribution(obj, unit, point)
            obj.selectedUnits(end+1) = SelectedUnit(point.key, point.value, unit);
            obj.sumWaterConsumption = obj.sumWaterConsumption + point.value;
            obj.sumPower = obj.sumPower + point.key;
        end

        function resetState(obj)
            obj.selectedUnits = SelectedUnit.empty(0, 0);
            obj.sumWaterConsumption = 0;
            obj.sumPower = 0;
        end
    end
end
