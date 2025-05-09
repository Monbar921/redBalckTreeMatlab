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
    
        function selectedUnits = dispatchActivePower(obj, ...
                waterPressure, powerTask, deviation)
            arguments
                obj;
                waterPressure double;
                powerTask double;
                deviation double = obj.deviation;
            end
            
            remainedPowerTask = powerTask;
            processedUnits = containers.Map('KeyType', 'char', 'ValueType', 'any');
            selectedUnits = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            Utils.debug(sprintf(['dispatchActivePower: start dispatch active power for waterPressure = %f, ' ...
                'powerTask = %f, deviation = %f'], waterPressure, powerTask, deviation), true);
            
            for unit = 1:length(obj.units)
               Utils.debug(sprintf('dispatchActivePower: start loop for unit %d, remainedPowerTask = %f', unit, remainedPowerTask), true);
               [minWaterPoint, minUnit] = obj.getMinWaterUnit(waterPressure, remainedPowerTask, processedUnits);
               if ~isempty(minUnit)
                  processedUnits(minUnit.getName()) = nan;
                  selectedUnits(minUnit.getName()) = minWaterPoint;
                  remainedPowerTask = remainedPowerTask - minWaterPoint.key;

                  if remainedPowerTask <= 0
                      Utils.debug(sprintf('dispatchActivePower: powerTask is done'), true);
                      break;
                  end
               end
            end
        end
    end

    methods (Access = private)
        function [minWaterPoint, minUnit]= getMinWaterUnit(obj, waterPressure, powerTask, processedUnits)
            minWaterPoint = {};
            minUnit = {};
            minWater = inf;
            for idx = 1:length(obj.units)
                unit = obj.units(idx);
                if ~unit.getIsActive() || ~isnan(obj.getValueFromMap(processedUnits, unit.getName))
                    continue;
                end

                tree = unit.getCharacteristic(waterPressure);
                if ~isempty(tree)
                    [node, nextNode] = tree.searchMinNode();
                    Utils.debug(sprintf('getMinWaterUnit: node.key %f, nextNode.key %f', ...
                        Utils.getNodeKey(node, inf), ...
                        Utils.getNodeKey(nextNode, inf)), true);

                    linearizedPoint = obj.linearizeWater(node, nextNode, powerTask);
                    Utils.debug(sprintf(['getMinWaterUnit: linearized key = %f' ...
                        ', value = %f'], linearizedPoint.key, linearizedPoint.value), true);

                    if isinf(linearizedPoint.value)
                        Utils.debug(sprintf('getMinWaterUnit: linearizedWater is inf, continue'), true);
                        continue;
                    elseif linearizedPoint.key < minWater
                        minWaterPoint = linearizedPoint;
                        minUnit = unit;
                        minWater = linearizedPoint.value;
                    end
                end
            end
        end

        function value = getValueFromMap(obj, map, key)
            try
                value = map(key);
            catch
                value = nan;
            end
            Utils.debug(sprintf('getValueFromMap: key %s, value = %s', key, value), true);
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
    end
end
