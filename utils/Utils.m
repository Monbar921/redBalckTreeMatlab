classdef Utils < handle
    methods (Static)
        function debug(outStr, isPrinted)
            if isPrinted
                disp(outStr);
            end
        end

        function result = getNodeKey(node, defaultResult)
            try
                result = node.key;
            catch
                result = defaultResult;
            end
        end
    end
end