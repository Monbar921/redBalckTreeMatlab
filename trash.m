addpath('tree');
addpath('unit');
addpath('manager');
addpath('utils');

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

manager = PowerManager();
manager.addUnit(unit1);
[minWater, conditionsMap] = manager.dispatchActivePower(3, 10);

fprintf('minWater = %g\n', minWater);

