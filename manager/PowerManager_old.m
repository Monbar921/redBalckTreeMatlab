classdef PowerManager < handle
    properties
        units (1,:) HydroelectricUnit;
    end

    methods
        function obj = PowerManager()
            % Initialize with an empty array of hydroelectric units.
            obj.units = HydroelectricUnit.empty;
        end
    
        function addUnit(obj, unit)
            obj.units(end+1) = unit; 
        end
    
        function [minWater, conditionsMap] = dispatchActivePower(obj, powerTask, waterPressure)
            % Initialize the DP state structure:
            %   .active = accumulated active power
            %   .water  = accumulated water consumption
            %   .path   = a cell array of chosen candidate contributions (per unit)
            dpState.active = 0;
            dpState.water  = 0;
            dpState.path   = {};
            dpState.unitName  = '';
            dp = dpState;  % starting DP state
    
            % Process each hydroelectric unit one by one.
            for unitIdx = 1:length(obj.units)
                unit = obj.units(unitIdx);
    
                % Retrieve the candidate tree (for the given water pressure)
                try
                    candidateTree = unit.getCharacteristic(waterPressure);
                catch
                    error('Hydro Unit %d does not have a candidate tree for water pressure %g.', unitIdx, waterPressure);
                end
                if isempty(candidateTree)
                    error('Candidate tree for Hydro Unit %d at water pressure %g is empty.', unitIdx, waterPressure);
                end
    
                % Instead of a recursive tree walk, apply an iterative in–order traversal.
                newDP = [];        % Will collect new DP states for this unit.
                node = candidateTree.root;
                stack = {};        % Use a cell array as an explicit stack.
    
                while ~isempty(stack) || ~isempty(node)
                    % Traverse left as far as possible.
                    while ~isempty(node)
                        stack{end+1} = node;
                        node = node.left;
                    end
                    % Pop the top of the stack to process the node.
                    node = stack{end};
                    stack(end) = [];
    
                    % Combine the candidate (a TreeNode) at the current node with the current DP state.
                    % Note: combineCandidate now passes along powerTask so that the new cumulative active
                    % power doesn’t exceed it.
                    candidateDP = obj.combineCandidate(dp, node, powerTask);
                    newDP = [newDP, candidateDP];  % Concatenate the resulting new DP states.
    
                    % Move to the right subtree.
                    node = node.right;
                end
    
                % Prune the DP states to remove any that are dominated by others.
                dp = obj.pruneDPStates(newDP);
                %dp(end).unitName = unit.name;
            end
    
            % At this point, dp holds all cumulative DP states (one from each branching possibility
            % across all units). We now select those that exactly hit the required powerTask.
            feasible = [];
            %conditionsMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            %minWater = inf;
            for s = 1:length(dp)
                if dp(s).active == powerTask
                    feasible = [feasible, dp(s)];
                end
            end

            if isempty(feasible)
                error('The required active power (%g) cannot be reached exactly at water pressure %g with the available units.', powerTask, waterPressure);
            end
    
            % Among the feasible states, choose the one with the minimum water consumption.
            minWater = inf;
            bestState = {};
            for s = 1:length(feasible)
                if feasible(s).water < minWater
                    minWater = feasible(s).water;
                    bestState = feasible(s);
                end
            end
    
            % Build the conditionsMap. Each hydroelectric unit’s chosen candidate (the TreeNode)
            % is stored with a key such as 'unit1', 'unit2', etc.
            conditionsMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for i = 1:length(bestState.path)
                key = sprintf('unit%d', i);
                %conditionsMap(key) = bestState.path{i};
                disp(bestState.path(1));
            end
        end
    end
    
    methods (Access = private)
        % combineCandidate:
        % Given an array of DP states (each a struct with fields:
        %   .active = accumulated active power,
        %   .water  = accumulated water consumption,
        %   .path   = cell array of chosen candidates)
        % and a candidate operating point (a TreeNode instance), create a new array of DP states,
        % adding the candidate’s contributions only if the new total active power does not exceed powerTask.
        %
        % Here candidate.key is used as the active power contribution and candidate.value as the water consumption.
        function candidateDP = combineCandidate(obj, dp, candidate, powerTask)
            % Initialize an empty array for the new DP states.
            candidateDP = [];
            % Iterate over each current DP state.
            for i = 1:length(dp)
                newActive = dp(i).active + candidate.key;  % candidate.key is the active power contribution.
                % Only allow the new state if it does not exceed the target active power.
                if newActive <= powerTask
                    newWater = dp(i).water + candidate.value;  % candidate.value is the water consumption.
                    if isempty(dp(i).path)
                        currentPath = {};
                    elseif iscell(dp(i).path)
                        currentPath = dp(i).path;
                    else
                        currentPath = {dp(i).path};
                    end
                    newPath = [currentPath, {candidate}];
                    candidateDP = [candidateDP, struct('active', newActive, 'water', newWater, 'path', newPath)]; %#ok<AGROW>
                end
            end
        end
    
        % pruneDPStates:
        % Given an array of DP states, remove any state that is "dominated" by another.
        % One DP state dominates another if it gets the same (or less) active power using
        % at least as much water consumption. This function sorts the states by water consumption
        % in ascending order, then keeps only the ones that provide a strictly higher active power.
        function prunedDP = pruneDPStates(obj, dpStates)
            if isempty(dpStates)
                prunedDP = dpStates;
                return;
            end
    
            % Sort the DP states by water consumption (ascending order).
            waters = arrayfun(@(s) s.water, dpStates);
            [~, order] = sort(waters);
            sortedStates = dpStates(order);
    
            prunedDP = sortedStates(1);  % Always retain the state with the minimum water consumption.
            bestActive = sortedStates(1).active;
            for i = 2:length(sortedStates)
                if sortedStates(i).active > bestActive
                    prunedDP(end+1) = sortedStates(i); %#ok<AGROW>
                    bestActive = sortedStates(i).active;
                end
            end
        end
    end
end
