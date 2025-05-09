classdef TreeNode < handle
    properties
        key;
        value;
        left = {};
        right = {};
        parent = {};
        color = "red";
    end
    
    methods
        function obj = TreeNode(key, value)
            obj.key = key;
            obj.value = value;
        end
    end
end
