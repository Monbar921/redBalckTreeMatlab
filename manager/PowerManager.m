classdef PowerManager < handle
    properties (Access = private)
        units (1,:) HydroelectricUnit;
    end

    methods
        function obj = PowerManager()
            obj.units = HydroelectricUnit.empty;
        end
    
        function addUnit(obj, unit)
            obj.units(end+1) = unit;
        end

        function minDistribution = extractMinDistribution(obj, distributions)
            fprintf('\nMin Distribution is\n');
            minDistribution = {};
            node = distributions.searchMinNode(distributions.root);
            if ~isempty(node)
                minDistribution = node;
                fprintf('min distribution water is %f\n', minDistribution.key);
                for idx = 1:length(node.value)
                    currentNode = node.value(idx);
                    fprintf('Value: %s\n',  currentNode.toString());
                end
            end
        end

        function distributions = makeDistributions(obj, ...
                waterPressure, powerTask)
            arguments
                obj;
                waterPressure double;
                powerTask double;
            end

            distributions = RedBlackTree();

            Utils.debug(sprintf(['makeDistributions: start dispatch active power for waterPressure = %f, ' ...
                'powerTask = %f'], waterPressure, powerTask), true);

            unitWaters = UnitWaterDistribution.empty;
            for idx = 1:length(obj.units)
                currentUnit = obj.units(idx);
                tree = obj.getUnitTree(currentUnit, waterPressure);
    
                if ~isempty(tree)
                    unitWaters = obj.putUnitPointsToDistribution(tree, currentUnit, powerTask, unitWaters);
                end
            end

            for idx = 1:length(obj.units)
               Utils.debug(sprintf('makeDistributions: start loop for unit %s', obj.units(idx).getName()), true);
               [distributions, unitWaters] = obj.makeUnitDistribution(powerTask, waterPressure, idx, distributions, unitWaters);
            end
        end

         function printDistributions(obj, distributions)
            fprintf('\nDistribution is\n');
            currentNode = distributions.searchMinNode(distributions.root);
            while ~isempty(currentNode)
                fprintf('Water consumption is %f\n', currentNode.key);
                unitsInDistribuion = currentNode.value;
    
                for idx = 1:length(unitsInDistribuion)
                    fprintf('Key: %f → Value: %s\n', currentNode.key, unitsInDistribuion(idx).toString());
                end

                currentNode = distributions.traverseInOrder(currentNode);
            end
         end
    end

    methods (Access = private)
        function [distributions, unitWaters] = makeUnitDistribution(obj, powerTask, waterPressure, currentUnitIdx, distributions, unitWaters)
            currentUnit = obj.units(currentUnitIdx);
            tree = obj.getUnitTree(currentUnit, waterPressure);

            if ~isempty(tree)
                %try get distibution with only this unit
                resPoint = obj.getAloneUnitDistribution(powerTask, tree);
                if ~isempty(resPoint)
                     distributions = obj.processDistribution(currentUnit, resPoint, powerTask, distributions, false);
                end

                tempUnitWaters = UnitWaterDistribution.empty;
                currentNode = tree.searchMinNode(tree.root);
                while ~isempty(currentNode)
                    if currentNode.key > powerTask
                        break;
                    end

                    for idx = 1:length(unitWaters)
                        newUnitWater = unitWaters(idx).copyAndWriteDistribution(currentUnit, currentNode, powerTask);
                        if isempty(newUnitWater)
                            continue;
                        end

                        if newUnitWater.sumPower == powerTask
                            distributions = obj.addResDistribuion(distributions, newUnitWater, false);
                        end

                        tempUnitWaters(end+1) = newUnitWater;
                    end

                    currentNode = tree.traverseInOrder(currentNode);
                end
                unitWaters = [unitWaters tempUnitWaters];
            end
        end

        function unitWaters = putUnitPointsToDistribution(obj, tree, unit, powerTask, unitWaters)
            currentNode = tree.searchMinNode(tree.root);
            while ~isempty(currentNode)
                if currentNode.key > powerTask
                    break;
                end
                unitWaterDistribution = UnitWaterDistribution();
                
                unitWaterDistribution.addDistribution(unit, currentNode);
                unitWaters(end+1) = unitWaterDistribution;

                currentNode = tree.traverseInOrder(currentNode);
            end
        end

        function unitTree = getUnitTree(obj, unit, waterPressure)
            unitTree = {};
            isActive = unit.getIsActive();
            unitName = unit.getName();
            Utils.debug(sprintf('getUnitTree: %s unit active status = %d', unitName ...
                ,isActive), true);

            if isActive
                tree = unit.getCharacteristic(waterPressure);
                Utils.debug(sprintf('getUnitTree: %s unit tree isEmpty = %d', unitName ...
                ,isempty(tree)), true);

                if ~isempty(tree)
                    unitTree = tree;
                end
            end
        end

        function combinations = findCharacteristicCombinations(units)
        
          numUnits = length(units);
          combinations = {};
        
          % Iterate through all possible combination lengths (from 1 to all units)
          for combinationLength = 1:numUnits
        
            % Generate all combinations of indices for the current length
            indices = nchoosek(1:numUnits, combinationLength); 
        
            % Iterate through each combination of indices
            for i = 1:size(indices, 1)
              currentCombination = {};
        
              % Iterate through the units in the current combination
              for j = 1:combinationLength
                 unitIndex = indices(i, j);
        
                 % Assuming 'characteristic' is a field containing the red-black tree
                 tree = units(unitIndex).characteristic;
        
                 % Extract values from the red-black tree. Replace this with your 
                 % actual method for retrieving data from your tree structure.
                 characteristicValues = tree.inorderTraversal(); % Example: inorder traversal
        
                 currentCombination = [currentCombination, characteristicValues]; 
              end
              combinations = [combinations, currentCombination];
            end
          end
        end


        function distributions = processDistribution(obj, unit, point, powerTask, distributions, isNeedReset)
            unitWaterDistribution = UnitWaterDistribution();
            unitWaterDistribution.addDistribution(unit, point);
            if powerTask - point.key == 0
                distributions = obj.addResDistribuion(distributions, unitWaterDistribution, isNeedReset);
            end
        end

        function resPoint = getAloneUnitDistribution(obj, powerTask, tree)
            resPoint = {};

            [node, nextNode] = tree.getLessOrEqualsTo(powerTask);
            Utils.debug(sprintf('getAloneUnitDistribution: node.key %f, nextNode.key %f', ...
                Utils.getNodeKey(node, inf), ...
                Utils.getNodeKey(nextNode, inf)), true);

            linearizedPoint = obj.linearizeWater(node, nextNode, powerTask);
            Utils.debug(sprintf(['getAloneUnitDistribution: linearized key = %f' ...
                ', value = %f'], linearizedPoint.key, linearizedPoint.value), true);

            if isinf(linearizedPoint.value)
                Utils.debug(sprintf('getAloneUnitDistribution: linearizedWater is inf'), true);
            else
                resPoint = linearizedPoint;
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

            if resultPoint.key ~= powerTask
                resultPoint.value = inf;
            end
        end

        function distributions = addResDistribuion(obj, distributions, unitWaterDistribution, isNeedReset)
            distributions.insert(unitWaterDistribution.sumWaterConsumption, unitWaterDistribution.selectedUnits);
            if isNeedReset
                unitWaterDistribution.resetState();
            end
        end
    end
end
