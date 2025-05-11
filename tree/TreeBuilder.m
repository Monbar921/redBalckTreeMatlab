classdef TreeBuilder < handle
    methods (Static)
        function [tree, inversedTree] = addToTreeAndInversedTree(tree, inversedTree, key, value)
            tree.insert(key, value);
            inversedTree.insert(key, value, true);
        end
    end
end
