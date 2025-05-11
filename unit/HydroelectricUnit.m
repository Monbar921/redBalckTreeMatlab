classdef HydroelectricUnit < handle
    properties (Access = private)
        characteristics = {};
        inversedCharacteristics = {};
        name;
        isActive;
    end

    methods
        function obj = HydroelectricUnit(name)
            obj.characteristics = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.inversedCharacteristics = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.name = name;
            obj.isActive = true;
        end

        function setCharacteristic(obj, pressure, characteristic)
            obj.characteristics(num2str(pressure)) = characteristic;
        end

        function setInversedCharacteristic(obj, pressure, characteristic)
            obj.inversedCharacteristics(num2str(pressure)) = characteristic;
        end

        function characteristic = getCharacteristic(obj, pressure)
            try
                characteristic = obj.characteristics(num2str(pressure));
            catch
                characteristic = {};
            end
        end

        function characteristic = getInversedCharacteristic(obj, pressure)
            try
                characteristic = obj.inversedCharacteristics(num2str(pressure));
            catch
                characteristic = {};
            end
        end

        function setIsActive(obj, isActive)
            obj.isActive = isActive;
        end

        function isActive = getIsActive(obj)
            isActive = obj.isActive;
        end

        function name = getName(obj)
            name = obj.name;
        end
    end
end
