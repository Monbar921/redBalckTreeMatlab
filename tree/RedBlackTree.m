classdef RedBlackTree < handle
    properties
        root = {};
        size = 0;
    end
    
    methods
        function obj = insert(obj, key, value, inversed)
            arguments
                obj;
                key double;
                value double;
                inversed logical  = false;
            end

            if inversed
                newNode = TreeNode(value, key);
            else
                newNode = TreeNode(key, value);
            end
            
            obj.root = obj.insertNode(obj.root, newNode);
            obj.root = fixViolations(obj.root, newNode);
            obj.root.color = "black"; % Ensure the root remains black
            obj.size = obj.size + 1;
        end

        function node = get(obj, key)
            node = searchNode(obj.root, key);
        end

        function printTree(obj)
            if isempty(obj.root)
                fprintf('The tree is empty.\n');
            else
                obj.printNode(obj.root, 0);
            end
        end

        function [predicateNode, nextNode] = getLessOrEqualsTo(obj, key)
            [predicateNode, nextNode] = obj.searchPredicateNode(obj.root, {}, key);
        end

        function node = searchMinNode(obj, root)
            if isempty(root) || isempty(root.left)
                node = root;
                return;
            end
            
            % Recursive case: keep going left
            node = obj.searchMinNode(root.left);
        end

        function currentNode = traverseTreeInOrderBeforeValue(obj, minNode, foundValue)
            currentNode = minNode;
            while ~isempty(currentNode) && currentNode.value > foundValue                
                % Move to the successor
                currentNode = obj.findSuccessor(currentNode);
            end
        end
    end

    methods (Access = private)
        function printNode(obj, node, depth)
            if isempty(node)
                return;
            end
            % Print right subtree first for better visualization
            obj.printNode(node.right, depth + 1);
            
            % Print current node with indentation based on depth
            fprintf('%d[%d (%s)]', depth, node.key, node.color);
            if ~isempty(node.left)
                fprintf(' (left %d %s)', node.left.key, node.left.color);
            end
            
            if ~isempty(node.right)
                fprintf(' (right %d %s)', node.right.key, node.right.color);
            end
        
            fprintf('\n');
            
            % Print left subtree
            obj.printNode(node.left, depth + 1);
        end

        function node = searchNode(obj, root, key)
            if isempty(root) || root.key == key
                node = root;
                return;
            elseif key < root.key
                node = obj.searchNode(root.left, key);
            else
                node = obj.searchNode(root.right, key);
            end
        end

        function [node, nextNode] = searchPredicateNode(obj, root, prevNode, key)
            if isempty(root)
                [node, nextNode] = obj.fillNodes(root, prevNode, key);
            elseif root.key == key
                node = root;
                nextNode = {};
            elseif ~isempty(prevNode) && key > root.key && key < prevNode.key ...
                && isempty(root.right)
                node = root;
                nextNode = prevNode;
            elseif ~isempty(prevNode) && key < root.key && key > prevNode.key ...
                && isempty(root.left)
                node = prevNode;
                nextNode = root;
            elseif key < root.key
                [node, nextNode] = obj.searchPredicateNode(root.left, root, key);
            else
                [node, nextNode] = obj.searchPredicateNode(root.right, root, key);
            end
        end

        function [node, nextNode] = fillNodes(obj, root, prevNode, key)
            if isempty(prevNode)
                node = root;
                nextNode = root;
            elseif prevNode.key > key
                node = prevNode;
                while ~isempty(node) && ~isempty(node.parent) && node.key > key
                    node = node.parent;
                end
                nextNode = prevNode;
            else
                node = root;
                nextNode = prevNode;
            end
        end

        function root = insertNode(obj, root, node)
            if isempty(root)
                root = node;
                return;
            end
        
            if node.key < root.key
                if isempty(root.left)
                    root.left = node;
                    node.parent = root; % 
                else
                    root.left = obj.insertNode(root.left, node);
                    root.left.parent = root; % 
                end
            else
                if isempty(root.right)
                    root.right = node;
                    node.parent = root;
                else
                    root.right = obj.insertNode(root.right, node);
                    root.right.parent = root; % 
                end
            end
        end

        function successor = findSuccessor(obj, node)
            %disp(node.key);
            if ~isempty(node.right)
                % Successor is the leftmost node in the right subtree
                successor = node.right;
                %disp(node.right.key);
                while ~isempty(successor.left)
                    %disp(successor.left.key);
                    successor = successor.left;
                end
            else
                % Successor is the nearest ancestor where node is in the left subtree
                successor = node.parent;
                while ~isempty(successor) && ~isempty(node) && ~isempty(successor.right) && node == successor.right
                    node = successor;
                    successor = successor.parent;
                end
            end
        end

    end
end

function root = fixViolations(root, node)
    while ~isempty(node.parent) && strcmp(node.parent.color, 'red')
        grandparent = node.parent.parent;

        if node.parent == grandparent.left
            uncle = grandparent.right;

            % Case 1: Uncle is red → Recolor parent, uncle, and grandparent
            if ~isempty(uncle) && strcmp(uncle.color, 'red')
                node.parent.color = 'black';
                uncle.color = 'black';
                grandparent.color = 'red';
                node = grandparent; % Move up the tree
            else
                % Case 2: Node is right child → Rotate Left (Make it left-heavy)
                if node == node.parent.right
                    node = node.parent;
                    root = rotateLeft(root, node);
                end
                % Case 3: Node is left child → Rotate Right and recolor
                node.parent.color = 'black';
                grandparent.color = 'red';
                root = rotateRight(root, grandparent);
            end
        else
            uncle = grandparent.left;

            % Case 1: Uncle is red → Recolor parent, uncle, and grandparent
            if ~isempty(uncle) && strcmp(uncle.color, 'red')
                node.parent.color = 'black';
                uncle.color = 'black';
                grandparent.color = 'red';
                node = grandparent; % Move up the tree
            else
                % Case 2: Node is left child → Rotate Right (Make it right-heavy)
                if node == node.parent.left
                    node = node.parent;
                    root = rotateRight(root, node);
                end
                % Case 3: Node is right child → Rotate Left and recolor
                node.parent.color = 'black';
                grandparent.color = 'red';
                root = rotateLeft(root, grandparent);
            end
        end
    end
    root.color = 'black';
end

function root = rotateLeft(root, node)
    rightChild = node.right;
    node.right = rightChild.left;
    
    if ~isempty(rightChild.left)
        rightChild.left.parent = node;
    end

    rightChild.parent = node.parent;

    if isempty(node.parent)
        root = rightChild;
    elseif node == node.parent.left
        node.parent.left = rightChild;
    else
        node.parent.right = rightChild;
    end

    rightChild.left = node;
    node.parent = rightChild;
end

function root = rotateRight(root, node)
    leftChild = node.left;
    node.left = leftChild.right;

    if ~isempty(leftChild.right)
        leftChild.right.parent = node;
    end

    leftChild.parent = node.parent;

    if isempty(node.parent)
        root = leftChild;
    elseif node == node.parent.right
        node.parent.right = leftChild;
    else
        node.parent.left = leftChild;
    end

    leftChild.right = node;
    node.parent = leftChild;
end
