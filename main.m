addpath('tree');
addpath('unit');
addpath('manager');

tree = RedBlackTree();
tree.insert(1, 5);
tree.insert(10, 13);
tree.insert(10, 9);
tree.insert(1, 10);
tree.insert(100, 10);
tree.insert(20, 10);
tree.insert(5, 10);
tree.insert(11, 10);
tree.insert(56, 10);
tree.insert(9, 3);

unit1 = HydroelectricUnit('GA1');
unit1.setCharacteristic(3, tree);


tree2 = RedBlackTree();
tree2.insert(4, 2);
tree2.insert(10, 13);
tree2.insert(10, 9);
tree2.insert(3, 10);
tree2.insert(100, 10);
tree2.insert(20, 10);
tree2.insert(5, 10);
tree2.insert(11, 10);
tree2.insert(56, 10);
tree2.insert(9, 4);

unit2 = HydroelectricUnit('GA2');
unit2.setCharacteristic(3, tree2);

manager = PowerManager();
manager.addUnit(unit1);
manager.addUnit(unit2);

[minWater, conditionsMap] = manager.dispatchActivePower(10, 3);
disp(minWater);

allKeys = keys(conditionsMap);

% Print all keys
disp(allKeys)
%charec.printTree();
%disp(length(unit1.characteristics));
%tree.printTree();