classdef SelectedUnit < handle
    properties (Access = private)
        point = struct('key', inf, 'value', inf);
        unit HydroelectricUnit;
    end

    methods
        function obj = SelectedUnit(key, value, unit)
            obj.point.key = key;
            obj.point.value = value;
            obj.unit = unit;
        end

        function setPoint(obj, key, value)
            obj.point.key = key;
            obj.point.value = value;
        end

        function point = getPoint(obj)
            point = obj.point;
        end

        function setUnit(obj, unit)
            obj.unit = unit;
        end

        function unit = getUnit(obj)
            unit = obj.unit;
        end

        function out = toString(obj)
            out = sprintf('point(key=%f,value=%f), unit(name=%s)', ...
                obj.point.key, obj.point.value, obj.unit.getName());
        end
    end
end
