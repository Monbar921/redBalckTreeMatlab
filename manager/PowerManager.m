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

                try
                    minTask = selectedTask(minKey);
                catch
                    minTask = {};
                end
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

            minWaterTaskHandler = TaskHandler(waterPressure, powerTask);
            maxWaterTaskHandler = TaskHandler(waterPressure, powerTask);
            maxPowerTaskHandler = TaskHandler(waterPressure, powerTask);
            selectedTask = containers.Map('KeyType', 'char', 'ValueType', 'any');
            resCounter = 0;

            Utils.debug(sprintf(['dispatchActivePower: start dispatch active power for waterPressure = %f, ' ...
                'powerTask = %f, deviation = %f'], waterPressure, powerTask, deviation), true);

            for idx = 1:length(obj.units)
               Utils.debug(sprintf('dispatchActivePower: start loop for unit %d, remainedPowerTask = %f', idx, minWaterTaskHandler.powerTask), true);
               if length(obj.units) > 1
                   [resCounter, selectedTask] = obj.calculateMinWaterUnit(minWaterTaskHandler, selectedTask, resCounter);
                   %[resCounter, selectedTask] = obj.calculateMaxPowerUnit(maxPowerTaskHandler, selectedTask, resCounter);
                   %[resCounter, selectedTask] = obj.calculateMaxWaterUnit(maxWaterTaskHandler, selectedTask, resCounter);
               end

               %1) find alone unit consumption
               [resCounter, selectedTask] = calculateAloneWaterUnit(obj, minWaterTaskHandler, selectedTask, resCounter);

               if length(obj.units) > 1
                   [resCounter, selectedTask] = obj.calculateAloneWaterUnit(maxPowerTaskHandler, selectedTask, resCounter);
                   %[resCounter, selectedTask] = obj.calculateAloneWaterUnit(maxWaterTaskHandler, selectedTask, resCounter);
               end
            end

            Utils.debug(sprintf('dispatchActivePower: remainedPowerTask = %f', minWaterTaskHandler.powerTask), true);
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
        function [resCounter, selectedTask] = calculateAloneWaterUnit(obj, taskHandler, selectedTask, resCounter)
            for idx = 1:length(obj.units)
                if ~obj.units(idx).getIsActive() || obj.getValueFromMap(taskHandler.processedUnits, obj.units(idx).getName)
                    continue;
                end

                [minWaterAlonePoint, minAloneUnit] = obj.getMinWaterAloneUnit(taskHandler.waterPressure, taskHandler.powerTask, obj.units(idx));
                [resCounter, selectedTask] =  taskHandler.processAloneWaterUnit(minAloneUnit, minWaterAlonePoint, selectedTask, resCounter);
            end
        end

        function [resCounter, selectedTask] = calculateMinWaterUnit(obj, taskHandler, selectedTask, resCounter)
           [minWaterPoint, minUnit] = obj.getMinWaterUnit(taskHandler);
           [resCounter, selectedTask] = taskHandler.processWaterUnitTask(minUnit, minWaterPoint, selectedTask, resCounter);
        end

        function [resCounter, selectedTask] = calculateMaxWaterUnit(obj, taskHandler, selectedTask, resCounter)
           [waterPoint, unit] = obj.getMaxWaterUnit(taskHandler);
           [resCounter, selectedTask] = taskHandler.processWaterUnitTask(unit, waterPoint, selectedTask, resCounter);
        end

        function [resCounter, selectedTask] = calculateMaxPowerUnit(obj, taskHandler, selectedTask, resCounter)
           [waterPoint, unit] = obj.getMaxPowerUnit(taskHandler);
           [resCounter, selectedTask] = taskHandler.processWaterUnitTask(unit, waterPoint, selectedTask, resCounter);
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

        function [minWaterPoint, minUnit] = getMinWaterUnit(obj, taskHandler)
            minWaterPoint = {};
            minUnit = {};
            minWater = inf;
            for idx = 1:length(obj.units)
                unit = obj.units(idx);
                
                if ~unit.getIsActive() || obj.getValueFromMap(taskHandler.processedUnits, unit.getName)
                    continue;
                end

                inversedTree = unit.getInversedCharacteristic(taskHandler.waterPressure);
                if ~isempty(inversedTree)
                    node = inversedTree.searchMinNode(inversedTree.root);

                    Utils.debug(sprintf('getMinWaterUnit: minNode node.key %f, node.value %f, unit %s', ...
                        node.value, node.key, unit.getName()), true);

                    node = obj.correctMinNodeToPowertTask(inversedTree, taskHandler.powerTask, node);

                    if isempty(node)
                        Utils.debug(sprintf('getMinWaterUnit: can not find point in characteristic'), true);
                        taskHandler.addProcessedUnits(unit.getName());
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
                    taskHandler.addProcessedUnits(unit.getName());
                end
            end
        end

        function [maxWaterPoint, maxUnit] = getMaxWaterUnit(obj, taskHandler)
            maxWaterPoint = {};
            maxUnit = {};
            maxWater = 0;
            for idx = 1:length(obj.units)
                unit = obj.units(idx);
                
                if ~unit.getIsActive() || obj.getValueFromMap(taskHandler.processedUnits, unit.getName)
                    continue;
                end

                inversedTree = unit.getInversedCharacteristic(taskHandler.waterPressure);
                if ~isempty(inversedTree)
                    node = inversedTree.searchMinNode(inversedTree.root);

                    Utils.debug(sprintf('getMaxWaterUnit: minNode node.key %f, node.value %f, unit %s', ...
                        node.value, node.key, unit.getName()), true);

                    node = obj.correctMinNodeToPowertTask(inversedTree, taskHandler.powerTask, node);

                    if isempty(node)
                        Utils.debug(sprintf('getMaxWaterUnit: can not find point in characteristic'), true);
                        taskHandler.addProcessedUnits(unit.getName());
                        continue;
                    end

                    Utils.debug(sprintf('getMaxWaterUnit: corrected minNode node.key %f, node.value %f', ...
                        node.value, node.key), true);

                    if node.key >= maxWater
                        maxWaterPoint = struct('key', node.value, 'value', node.key);
                        maxUnit = unit;
                        maxWater = node.key;
                        Utils.debug(sprintf('getMaxWaterUnit: new min point node.key %f, node.value %f', ...
                        maxWaterPoint.key, maxWaterPoint.value), true);
                    end
                else
                    taskHandler.addProcessedUnits(unit.getName());
                end
            end
        end

        function [waterPoint, selectedUnit] = getMaxPowerUnit(obj, taskHandler)
            waterPoint = {};
            selectedUnit = {};
            minWater = inf;
            for idx = 1:length(obj.units)
                unit = obj.units(idx);
                
                if ~unit.getIsActive() || obj.getValueFromMap(taskHandler.processedUnits, unit.getName)
                    continue;
                end

                tree = unit.getCharacteristic(taskHandler.waterPressure);
                if ~isempty(tree)
                    [predicateNode, nextNode] = tree.getLessOrEqualsTo(taskHandler.powerTask);

                    if isinf(Utils.getNodeKey(predicateNode, inf)) && ~isinf(Utils.getNodeKey(nextNode, inf))
                        predicateNode = nextNode;
                    else
                        Utils.debug(sprintf('getMaxPowerUnit: can not find point'), true);
                        continue;
                    end

                    Utils.debug(sprintf('getMaxPowerUnit: minNode node.key %f, node.value %f, unit %s', ...
                        predicateNode.key, predicateNode.value, unit.getName()), true);

                    if predicateNode.value < minWater
                        waterPoint = struct('key', predicateNode.key, 'value', predicateNode.value);
                        selectedUnit = unit;
                        minWater = predicateNode.value;
                        Utils.debug(sprintf('getMaxPowerUnit: new water point node.key %f, node.value %f', ...
                        waterPoint.key, waterPoint.value), true);
                    end
                else
                    taskHandler.addProcessedUnits(unit.getName());
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
            elseif ~isinf(nodeKey) && ~isinf(nextNodeKey) && (powerTask >= nodeKey && powerTask <= nextNodeKey)
                result = node.value + ((nextNode.value - node.value)/(nextNode.key - node.key))*(powerTask - node.key);
                resultPoint = struct('key', powerTask, 'value', result);
            elseif isinf(nodeKey) && ~isinf(nextNodeKey)
                resultPoint = struct('key', nextNodeKey, 'value', nextNode.value);
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
