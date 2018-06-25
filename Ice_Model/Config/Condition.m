classdef Condition < matlab.mixin.Copyable
    properties
        Constant
        Present
        Initial
        Variable
    end
    methods
        % Constructor
        function self = Condition(Constant,Present,Initial)
            % With no input arguments, define default conditions
            if nargin==0;
                Initial = DefineInitials(self.Initial);
                self.Initial = Initial;
                
                Constant = DefineConstants(self.Constant,self.Initial);
                self.Constant = Constant;
                
                self.Undeal;
            % Unless specified - then use those
            else
                self.Constant = Constant;
                self.Initial = Initial;
                self.Present = Present;
            end
        end
        %% Add Condition
        function self = AddCondition(self,Constant,Initial);
            self = [self,Condition(Constant,[],Initial)];
        end
        %% Change parameters ##NEEDED?
        function ParamChange(self,Number,varargin);
            for n=1:2:(numel(varargin));
                for m = 1:numel(Number);
                % Get fieldname
                Temp = strsplit(varargin{n},'.');
                Temp2 = strsplit(Temp{end},'(');
                Left = strjoin([[Temp{1},'(',num2str(Number(m)),')'],Temp(2:end-1)],'.');
                Right = Temp2(1);
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
                    eval(['self.',strjoin([Left,Temp(2)],'.'),'=varargin{n+1};']);
                else
                    warning('Unsure what that means, try again');
                end
                end
            end
        end
        
        %% Add values
        function AddConstants(self);
            Constant = DefinePhysicalConstants_OO(self.Constant(end));
            Constant = DefineBiologicalConstants_OO(Constant);
            Constant = DefineCarbonateChemistryConstants_OO(Constant);
            self.Constant = [self.Constant,Constant];
        end
        
        function AddInitials(self);
            Initial = DefineInitialConditions_OO(self.Initial(end));
            self.Initial = [self.Initial,Initial];
        end
        
        function AddVariable(self,what,number,string)
            self.Variable = [self.Variable;{strsplit(what,'.'),number,str2func(['@(t,Conditions)',string])}];
        end
        
        function RmVariables(self);
            self.Variable = [];
        end
        
        %%
        function UpdatePresent(self);
            TempNames = fieldnames(self.Constant);
%             UntempNames = fieldnames(self.Present);
            UntempNames = '';
            DoNames = setdiff(TempNames,UntempNames);
            for n = 1:length(DoNames);
                self.Present.(DoNames{n}) = self.Constant.(DoNames{n});
            end
        end

        %% Perturbation handling
        function Perturb(self,Perturbations);
            for n = 1:size(Perturbations,1);
                if ~isempty(Perturbations{n,1});
%                     self.Initial.(Perturbations{n,1}{1})(str2double(Perturbations{n,1}{2})) = eval(['self.Initial.',(Perturbations{n,1}{3})]);
                    self.Initial.(Perturbations{n,1}{1})(str2double(Perturbations{n,1}{2})) = str2double((Perturbations{n,1}{3}));
                end
            end
            self.Undeal;
        end
        
        %%
        function Deal(self);
            self.Initial.Atmosphere_CO2 = self.Initial.Conditions(1);
            self.Initial.Algae = self.Initial.Conditions(2);
            self.Initial.Phosphate = self.Initial.Conditions(3:4);
            self.Initial.DIC = self.Initial.Conditions(5:6);
            self.Initial.Alkalinity = self.Initial.Conditions(7:8);
            self.Initial.Atmosphere_Temperature = self.Initial.Conditions(9);
            self.Initial.Ocean_Temperature = self.Initial.Conditions(10:11);
            self.Initial.Silicate = self.Initial.Conditions(12);
            self.Initial.Carbonate = self.Initial.Conditions(13);
            self.Initial.Silicate_Weathering_Fraction = self.Initial.Conditions(14);
            self.Initial.Carbonate_Weathering_Fraction = self.Initial.Conditions(15);
            self.Initial.Radiation = self.Initial.Conditions(16);
            self.Initial.Ice = self.Initial.Conditions(17);
            self.Initial.Sea_Level = self.Initial.Conditions(18);
            self.Initial.Snow_Line = self.Initial.Conditions(19);
        end
        function Undeal(self);
            self.Initial.Conditions = [self.Initial.Atmosphere_CO2; %1
                                       self.Initial.Algae; %2
                                       self.Initial.Phosphate; %3,4
                                       self.Initial.DIC; %5,6
                                       self.Initial.Alkalinity; %7,8
                                       self.Initial.Atmosphere_Temperature; %9
                                       self.Initial.Ocean_Temperature; %10,11
                                       self.Initial.Silicate; %12
                                       self.Initial.Carbonate; %13
                                       self.Initial.Silicate_Weathering_Fraction; %14
                                       self.Initial.Carbonate_Weathering_Fraction; %15
                                       self.Initial.Radiation; %16
                                       self.Initial.Ice; %17
                                       self.Initial.Sea_Level; %18
                                       self.Initial.Snow_Line]; %19
        end
    end
end