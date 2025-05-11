addpath('tree');
addpath('unit');
addpath('manager');
addpath('utils');

tree = RedBlackTree();
inversedTree = RedBlackTree();
TreeBuilder.addToTreeAndInversedTree(tree, inversedTree, 1, 5);
TreeBuilder.addToTreeAndInversedTree(tree, inversedTree, 10, 13);
TreeBuilder.addToTreeAndInversedTree(tree, inversedTree, 100, 10);
TreeBuilder.addToTreeAndInversedTree(tree, inversedTree, 20, 10);
TreeBuilder.addToTreeAndInversedTree(tree, inversedTree, 5, 2);
TreeBuilder.addToTreeAndInversedTree(tree, inversedTree, 11, 10);
TreeBuilder.addToTreeAndInversedTree(tree, inversedTree, 56, 10);
TreeBuilder.addToTreeAndInversedTree(tree, inversedTree, 9, 7);

tree2 = RedBlackTree();
inversedTree2 = RedBlackTree();
TreeBuilder.addToTreeAndInversedTree(tree2, inversedTree2, 4, 5);
TreeBuilder.addToTreeAndInversedTree(tree2, inversedTree2, 10, 13);
TreeBuilder.addToTreeAndInversedTree(tree2, inversedTree2, 100, 30);
TreeBuilder.addToTreeAndInversedTree(tree2, inversedTree2, 20, 10);
TreeBuilder.addToTreeAndInversedTree(tree2, inversedTree2, 5, 10);
TreeBuilder.addToTreeAndInversedTree(tree2, inversedTree2, 11, 10);
TreeBuilder.addToTreeAndInversedTree(tree2, inversedTree2, 1, 10);
TreeBuilder.addToTreeAndInversedTree(tree2, inversedTree2, 9, 3);

tree.printTree();

unit1 = HydroelectricUnit('GA1');
unit1.setCharacteristic(3, tree);
unit1.setInversedCharacteristic(3, inversedTree);

unit2 = HydroelectricUnit('GA2');
unit2.setCharacteristic(3, tree2);
unit2.setInversedCharacteristic(3, inversedTree2);

manager = PowerManager();
manager.addUnit(unit1);
manager.addUnit(unit2);

%tree.traverseTreeInOrder(tree.searchMinNode(tree.root));


selectedUnits = manager.dispatchActivePower(3, 40);

disp('result');
minTask = manager.extractMinFromTask(selectedUnits, 40);
manager.printSelectedTask(minTask);

manager.printDispatchTask(selectedUnits);

%fprintf('minWater = %g\n', minWater);

