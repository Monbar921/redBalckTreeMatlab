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
    
        function [minWater, selectedUnits] = dispatchActivePower(obj, ...
                waterPressure, powerTask, deviation)
            arguments
                obj;
                waterPressure double;
                powerTask double;
                deviation double = obj.deviation;
            end

            minWater = 0;
            selectedUnits = [];

            if isempty(deviation) || isnan(deviation)
                deviation = obj.deviation;
            end
            
            [firstUnit, firstUnitTree] = obj.getFirstNonNullCharacteristicUnit(waterPressure);
            
            Utils.debug(sprintf('firstUnit %d', firstUnit), true);
            if firstUnit ~= 0
                currentNode = firstUnitTree.searchMinNode(firstUnitTree.root);
                currentPower = currentNode.key;
                currentConsumption = currentNode.value;

                Utils.debug(sprintf('currentPower %d currentConsumption %d', currentPower, currentConsumption), true);
                
                for point = 1:firstUnitTree.size
                    for unitIdx = firstUnit:length(obj.units)
                        Utils.debug(sprintf('loop iteration: point %d, unit %d', point, unitIdx), true);
                        unit = obj.units(unitIdx);
        
                        if ~unit.getIsActive()
                            continue;
                        end
            
                        characteristic = unit.getCharacteristic(waterPressure);
        
                        if isempty(characteristic)
                            fprintf('Characteristic for Hydro Unit %s at water pressure %g is empty\n' ...
                                , unit.getName, waterPressure);
                        else
                            if unitIdx == firstUnit
                                if currentPower ~= currentNode.key ...
                                   && currentConsumption ~= currentNode.value
                                    currentNode = currentNode.right;
                                    currentPower = currentNode.key;
                                    currentConsumption = currentNode.value;
                                else
                                    continue;
                                end
                            end


                        end
                    end
                end
            end
        end
    end

    methods (Access = private)
        function nodes = collectXY(obj, node)
            nodes = TreeNode.empty(0,1);
            if isempty(node)
                return;
            end
            nodes = [nodes, obj.collectXY(node.left)];
            nodes(end+1) = node;
            nodes = [nodes, obj.collectXY(node.right)];
        end

        function [unitIdx, tree] = getFirstNonNullCharacteristicUnit(obj, waterPressure)
            idx = length(obj.units);
            treeLength = 0;
            for idx = 1:length(obj.units)
                unit = obj.units(idx);
                tree = unit.getCharacteristic(waterPressure);
                if ~isempty(tree)
                    unitIdx = idx;
                end
            end
        end

    end
end
