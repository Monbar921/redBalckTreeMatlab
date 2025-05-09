classdef Utils < handle
    methods (Static)
        function debug(outStr, isPrinted)
            if isPrinted
                disp(outStr);
            end
        end
    end
end