classdef PowerManager < handle
    properties (Access = private)
        units (1,:) HydroelectricUnit;
        deviation;
    end

    methods
        function obj = PowerManager()
            obj.units = HydroelectricUnit.empty;
            obj.deviation = 1;
        end
    
        function addUnit(obj, unit)
            obj.units(end+1) = unit;
        end

        function minTask = extractMinFromTask(obj, selectedTask, powerTask)
            minKey = '';
            minWater = inf;

            if ~isempty(selectedTask)
                keysList = keys(selectedTask);  % Get all keys
                valuesList = values(selectedTask);  % Get all values
                for i = 1:length(keysList)              
                    key = keysList{i};
                    valueArr = valuesList{i};
                    summaryPower = 0;
                    summaryWater = 0;

                    for idx = 1:length(valueArr)
                        summaryPower = summaryPower + valueArr(idx).getPoint().key;
                        summaryWater = summaryWater + valueArr(idx).getPoint().value;
                    end

                    if summaryPower == powerTask && summaryWater < minWater
                        minWater = summaryWater;
                        minKey = key;
                    end
                end
                minTask = selectedTask(minKey);
            end
        end
    
        function selectedTask = dispatchActivePower(obj, ...
                waterPressure, powerTask, deviation)
            arguments
                obj;
                waterPressure double;
                powerTask double;
                deviation double = obj.deviation;
            end
            
            remainedPowerTask = powerTask;
            processedUnits = containers.Map('KeyType', 'char', 'ValueType', 'any');
            selectedTask = containers.Map('KeyType', 'char', 'ValueType', 'any');
            selectedUnits = SelectedUnit.empty(0, 0);
            resCounter = 0;

            Utils.debug(sprintf(['dispatchActivePower: start dispatch active power for waterPressure = %f, ' ...
                'powerTask = %f, deviation = %f'], waterPressure, powerTask, deviation), true);

            %1) find alone unit consumption

            %2) find the miin n-th min unit consumption and compete with n+1 to power task 
            for idx = 1:length(obj.units)
               Utils.debug(sprintf('dispatchActivePower: start loop for unit %d, remainedPowerTask = %f', idx, remainedPowerTask), true);
               [resCounter, selectedTask] = calculateAloneUnit(obj, waterPressure, powerTask, obj.units(idx), selectedTask, resCounter);

               if length(obj.units) > 1 && remainedPowerTask > 0
                   if remainedPowerTask ~= powerTask && remainedPowerTask > 0
                       for aloneIdx = idx:length(obj.units)
                           [resCounter, selectedTask] = calculateAloneUnit(obj, waterPressure, remainedPowerTask, obj.units(aloneIdx), selectedTask, resCounter, selectedUnits);
                       end
                   end

                   [minWaterPoint, minUnit] = obj.getMinWaterUnit(waterPressure, remainedPowerTask, processedUnits);
                   
                   if ~isempty(minUnit)
                      selectedUnits(end+1) = SelectedUnit(minWaterPoint.key, minWaterPoint.value, minUnit);
                      remainedPowerTask = remainedPowerTask - minWaterPoint.key;
                      if remainedPowerTask <= 0
                          selectedTask(num2str(resCounter)) = selectedUnits;
                          resCounter = resCounter + 1;
                      end

                      processedUnits(minUnit.getName()) = true;
                   end
               end
            end

            Utils.debug(sprintf('dispatchActivePower: remainedPowerTask = %f', remainedPowerTask), true);
        end

        function printDispatchTask(obj, selectedUnitsMap)
            if ~isempty(selectedUnitsMap)
                keysList = keys(selectedUnitsMap);  % Get all keys
                valuesList = values(selectedUnitsMap);  % Get all values
                for i = 1:length(keysList)
                    fprintf('\n');
                
                    key = keysList{i};
                    valueArr = valuesList{i};
                
                    for idx = 1:length(valueArr)
                        fprintf('Key: %s → Value: %s\n', key, valueArr(idx).toString());
                    end
                end
            end
        end

        function printSelectedTask(obj, selectedUnitsArr)
            if ~isempty(selectedUnitsArr)
                for i = 1:length(selectedUnitsArr)
                    fprintf('%s\n', selectedUnitsArr(i).toString());
                end
            end
        end
    end

    methods (Access = private)
        function [resCounter, selectedTask] = calculateAloneUnit(obj, waterPressure, powerTask, unit, selectedTask, resCounter, selectedUnits)
            if nargin == 6
                selectedAloneUnits = SelectedUnit.empty(0, 0);
            else
                selectedAloneUnits = selectedUnits;
            end
            
            [minWaterAlonePoint, minAloneUnit] = obj.getMinWaterAloneUnit(waterPressure, powerTask, unit);
              
            if ~isempty(minAloneUnit)
              selectedAloneUnits(end+1) = SelectedUnit(minWaterAlonePoint.key, minWaterAlonePoint.value, minAloneUnit);
              selectedTask(num2str(resCounter)) = selectedAloneUnits;
              resCounter = resCounter + 1;
            end
        end

        function [minWaterPoint, minUnit] = getMinWaterAloneUnit(obj, waterPressure, powerTask, unit)
            minWaterPoint = {};
            minUnit = {};

            if unit.getIsActive()
                tree = unit.getCharacteristic(waterPressure);
                if ~isempty(tree)
                    [node, nextNode] = tree.getLessOrEqualsTo(powerTask);
                    Utils.debug(sprintf('getMinWaterAloneUnit: node.key %f, nextNode.key %f', ...
                        Utils.getNodeKey(node, inf), ...
                        Utils.getNodeKey(nextNode, inf)), true);
    
                    linearizedPoint = obj.linearizeWater(node, nextNode, powerTask);
                    Utils.debug(sprintf(['getMinWaterAloneUnit: linearized key = %f' ...
                        ', value = %f'], linearizedPoint.key, linearizedPoint.value), true);
    
                    if isinf(linearizedPoint.value)
                        Utils.debug(sprintf('getMinWaterAloneUnit: linearizedWater is inf'), true);
                    else
                        minWaterPoint = linearizedPoint;
                        minUnit = unit;
                    end
                end
            end
        end

        function [minWaterPoint, minUnit] = getMinWaterUnit(obj, waterPressure, powerTask, processedUnits)
            minWaterPoint = {};
            minUnit = {};
            minWater = inf;
            for idx = 1:length(obj.units)
                unit = obj.units(idx);
                
                if ~unit.getIsActive() || obj.getValueFromMap(processedUnits, unit.getName)
                    continue;
                end

                inversedTree = unit.getInversedCharacteristic(waterPressure);
                if ~isempty(inversedTree)
                    node = inversedTree.searchMinNode(inversedTree.root);

                    Utils.debug(sprintf('getMinWaterUnit: minNode node.key %f, node.value %f, unit %s', ...
                        node.value, node.key, unit.getName()), true);

                    node = obj.correctMinNodeToPowertTask(inversedTree, powerTask, node);

                    if isempty(node)
                        Utils.debug(sprintf('getMinWaterUnit: can not find point in characteristic'), true);
                        processedUnits(unit.getName()) = true;
                        continue;
                    end

                    Utils.debug(sprintf('getMinWaterUnit: corrected minNode node.key %f, node.value %f', ...
                        node.value, node.key), true);

                    if node.key < minWater
                        minWaterPoint = struct('key', node.value, 'value', node.key);
                        minUnit = unit;
                        minWater = node.key;
                        Utils.debug(sprintf('getMinWaterUnit: new min point node.key %f, node.value %f', ...
                        minWaterPoint.key, minWaterPoint.value), true);
                    end
                else
                    processedUnits(unit.getName()) = true;
                end
            end
        end

        function value = getValueFromMap(obj, map, key)
            try
                value = map(key);
            catch
                value = false;
            end
        end

        function resultPoint = linearizeWater(obj, node, nextNode, powerTask)
            nodeKey = Utils.getNodeKey(node, inf);
            nextNodeKey = Utils.getNodeKey(nextNode, inf);

            if ~isinf(nodeKey) && nodeKey == powerTask
                resultPoint = struct('key', powerTask, 'value', node.value);
            elseif ~isinf(nodeKey) && ~isinf(nextNodeKey)
                result = node.value + ((nextNode.value - node.value)/(nextNode.key - node.key))*(powerTask - node.key);
                resultPoint = struct('key', powerTask, 'value', result);
            elseif isinf(nodeKey) && ~isinf(nextNodeKey)
                resultPoint = struct('key', node.key, 'value', nextNode.value);
            elseif ~isinf(nodeKey) && isinf(nextNodeKey)
                resultPoint = struct('key', powerTask, 'value', inf);
            else
                resultPoint = struct('key', powerTask, 'value', inf);
            end
        end

        function correctedNode = correctMinNodeToPowertTask(obj, tree, powerTask, node)
            correctedNode = node;
            if node.value > powerTask
                correctedNode = {};
                if ~isempty(tree)
                    node = tree.traverseTreeInOrderBeforeValue(node, powerTask);
    
                    if ~isempty(node) && node.value <= powerTask
                        Utils.debug(sprintf(['correctMinNodeToPowertTask: node.key = %f,' ...
                            'node.value=%f'], node.value, node.key), true);
                        correctedNode = node;
                    end
                end
            end
        end
    end
end
