classdef TaskHandler < handle
    properties
        selectedUnits;
        waterPressure;
        powerTask;
        processedUnits;
    end

    methods
        function obj = TaskHandler(waterPressure, powerTask)
            obj.powerTask = powerTask;
            obj.waterPressure = waterPressure;

            obj.processedUnits = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.selectedUnits = SelectedUnit.empty(0, 0);
        end

        function [resCounter, selectedTask] = processAloneWaterUnit(obj, unit, waterPoint, selectedTask, resCounter)
            if ~isempty(unit)
              selectedAloneUnits = obj.selectedUnits;
              selectedAloneUnits(end+1) = SelectedUnit(waterPoint.key, waterPoint.value, unit);
              selectedTask(num2str(resCounter)) = selectedAloneUnits;
              resCounter = resCounter + 1;
            end
        end

        function [resCounter, selectedTask] = processWaterUnitTask(obj, unit, waterPoint, selectedTask, resCounter)          
            if ~isempty(unit)
              obj.selectedUnits(end+1) = SelectedUnit(waterPoint.key, waterPoint.value, unit);
              obj.powerTask = obj.powerTask - waterPoint.key;
              if obj.powerTask <= 0
                  selectedTask(num2str(resCounter)) = obj.selectedUnits;
                  resCounter = resCounter + 1;
              end
            
              obj.addProcessedUnits(unit.getName());
            end
        end

        function addProcessedUnits(obj, unitName)
            obj.processedUnits(unitName) = true;
        end
    end
end
