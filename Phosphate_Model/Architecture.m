classdef Architecture < handle
    properties
        BoxDepths
        BoxArea
        TotalBoxes
        Constant
        Initial
        Volumes
    end
    methods
        function self = Architecture(BoxDepths,Area,Initial)
            self.Initial = Initial;
            self.BoxArea = Area;
            self.BoxDepths = BoxDepths;
            self.TotalBoxes = numel(self.BoxDepths);
            self.Volumes = self.BoxArea.*self.BoxDepths;
            
            self.Constant = DefinePhysicalConstants_OO(self.Constant);
            self.Constant = DefineBiologicalConstants_OO(self.Constant);
            self.Constant = DefineCarbonateChemistryConstants_OO(self.Constant);
        end
        function self = RedefineBiologicalConstants(self);
            self.Constant = RedefineBiologicalConstants_OO(self.Constant);
        end
        function self = ParamChange(self,varargin);
            for n=1:2:(numel(varargin));
                % Get fieldname
                Temp = strsplit(varargin{n},'.');
                Left = strjoin(Temp(1:end-1),'.');
                Right = Temp(end);
                % Check for field
                Exists = isfield(eval(['self.',Left]),Right);
                % Warning if field doesn't exist
                if ~Exists;
                    warning(['Assigning to previously non existent variable - ',varargin{n}]);
                    UserInput = input('Would you like to continue?','s');
                else
                    UserInput = 'y';
                end
                if UserInput=='n';
                    error('Stopping run due to parameter change.');
                elseif UserInput=='y';
                    % Rewrite constant
                    eval(['self.',varargin{n},'=varargin{n+1};']);
                else
                    warning('Unsure what that means, try again');
                end
            end
        end
    end
end