classdef TreeNode < handle
    properties
        key;
        left = {};
        right = {};
        parent = {};
        color = "red";
    end
    methods
        function obj = TreeNode(key)
            obj.key = key;
        end
    end
end