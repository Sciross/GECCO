classdef Condition < matlab.mixin.Copyable
    properties
        Initials@Initial
        Functionals@Functional
        Constants@Parameter
        Presents@Parameter
        Perturbations@Perturbation
        Transients@Transient
    end
    properties (Hidden=true)
    end
    methods(Static)
        function Properties_Map = GetPropertiesMap(Input);
            Properties = properties(Input);
            Properties_Deep = cell(numel(Properties),1);
            for Property_Index = 1:numel(Properties);
                if ~isfloat(Input.(Properties{Property_Index}));
                    Properties_Deep{Property_Index} = properties(Input.(Properties{Property_Index}));
                end
            end
            Properties_Map = [Properties,Properties_Deep];
            Properties_Number_Map = ones(size(Properties_Map));
            for Property_Index = 1:size(Properties_Number_Map,1);
                for Depth_Index = 1:size(Properties_Number_Map,2);
                    if Depth_Index == size(Properties_Number_Map,2);
                        if isempty(Properties_Map{Property_Index,Depth_Index});
                            Properties_Number_Map(Property_Index,Depth_Index) = 0;
                        end
                    elseif isempty(Properties_Map{Property_Index,Depth_Index+1});
                        Properties_Number_Map(Property_Index,Depth_Index) = 1;
                    else
                        Properties_Number_Map(Property_Index,Depth_Index) = 0;
                    end
                end
            end
        end        
        function Shallow_Names = GetFirstLevelNames(Input);
            Shallow_Names = string(fieldnames(Input));
        end
        function Deep_Names = GetSecondLevelNames(Input);
            Shallow_Names = Condition.GetFirstLevelNames(Input);
            for Shallow_Index = 1:numel(Shallow_Names);
                Deep_Names{Shallow_Index} = string(fieldnames(Input.(Shallow_Names{Shallow_Index})));
            end   
        end
        function [Shallow_Names,Deep_Names] = GetShallowAndDeepNames(Input);
            Shallow_Names = Condition.GetShallowNames(Input);
            Deep_Names = Condition.GetDeepNames(Input);
        end
        function Dotted_Names = GetDottedNames(Input);
            Shallow_Names = string(Condition.GetFirstLevelNames(Input));
            for Shallow_Index = 1:numel(Shallow_Names);
                Deep_Names{Shallow_Index} = string(fieldnames(Input.(Shallow_Names{Shallow_Index})));
            end
            
            Dotted_Names = [];
            for Shallow_Index = 1:numel(Shallow_Names);
                for Deep_Index = 1:numel(Deep_Names{Shallow_Index});
                    Dotted_Names = [Dotted_Names;strjoin([Shallow_Names(Shallow_Index),Deep_Names{Shallow_Index}(Deep_Index)],".")];
                end
            end
        end
    end
    methods
        function self = Condition(Constants,Presents,Initials)
            % Constructor
            % With no input arguments, define default conditions
            if nargin==0;
                self.Initials = Initial();
                self.Initials.Undeal();
                self.Functionals = Functional();
                self.Constants = Parameter();
                self.Transients = Transient();
                self.Perturbations = Perturbation();
                
            % Unless specified - then use those
            else
                self.Constant = Constants;
                self.Initial = Initials;
                self.Present = Presents;
            end
        end
        function self = AddCondition(self,Constant,Initial);
            self = [self,Condition(Constant,[],Initial)];
        end
        
        function ParamChange(self,Number,varargin);
        %% Change parameters ##NEEDED?
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
        function AddVariable(self,what,number,string)
            self.Variable = [self.Variable;{strsplit(what,'.'),number,str2func(['@(t,Conditions)',string])}];
        end
        function RemoveVariables(self);
            self.Variable = [];
        end
        
        function Size = GetSizeOf(self,Type,Group,Variable);
            if strcmp(Type,"Presents") || strcmp(Type,"Constants");
            Size = numel(self.(Type).(Group).(Variable));
            elseif strcmp(Type,"Initials");
                if nargin==4;
                    Size = numel(self.(Type).(Variable));
                else
                    Size = numel(self.(Type).(Group));
                end
            end
        end
        
        function UpdatePresent(self);
%             self.Presents = copy(self.Constants);
            self.Presents(1).Architecture = copy(self.Constants.Architecture);
            self.Presents.Phosphate = copy(self.Constants.Phosphate);
            self.Presents.Carbon = copy(self.Constants.Carbon);
            self.Presents.Seafloor = copy(self.Constants.Seafloor);
            self.Presents.Outgassing = copy(self.Constants.Outgassing);
            self.Presents.Ice = copy(self.Constants.Ice);
            self.Presents.Weathering = copy(self.Constants.Weathering);
            self.Presents.Energy = copy(self.Constants.Energy);
            self.Presents.Carbonate_Chemistry = copy(self.Constants.Carbonate_Chemistry);
            self.Presents.Carbonate_Chemistry.Temperature = self.Initials.Ocean_Temperature;
%             self.Presents.Carbonate_Chemistry.Salinity = self.Presents.Salinity;
%             self.Presents.Carbonate_Chemistry.Pressure = self.Presents.Pressure;
            self.Presents.Carbonate_Chemistry.DIC = self.Initials.DIC;
            self.Presents.Carbonate_Chemistry.Alkalinity = self.Initials.Alkalinity;
            self.Presents.Carbonate_Chemistry.Depths = self.Presents.Architecture.Ocean_Midpoints;
        end
        
        function PerformStandardOutgassingPerturbation(self);
            Time_Array = 1:self.Constants.Outgassing.Temporal_Resolution:(numel(self.Initials.Outgassing)*self.Constants.Outgassing.Temporal_Resolution);
            self.Initials.PerformStandardOutgassingPerturbation(Time_Array);
        end

        function Perturb(self,Perturbations,Chunk_Number);
            %% Perturbation handling
            for Perturbation_Index = 1:size(Perturbations,1);
                if ~isempty(Perturbations{Perturbation_Index,1}) && (Perturbations{Perturbation_Index,1})==Chunk_Number;
                    if strcmp(Perturbations{Perturbation_Index,2},"Initials");
                        self.(Perturbations{Perturbation_Index,2}).(Perturbations{Perturbation_Index,4})(Perturbations{Perturbation_Index,5}) = feval(Perturbations{Perturbation_Index,6},self);
                    elseif strcmp(Perturbations{Perturbation_Index,2},"Constants");
                        self.(Perturbations{Perturbation_Index,2}).(Perturbations{Perturbation_Index,3}).(Perturbations{Perturbation_Index,4})(Perturbations{Perturbation_Index,5}) = feval(Perturbations{Perturbation_Index,6},self);
                    else
                        error("The type of the perturbed variable was not recognised");
                    end
                end
            end
            self.Initials.Undeal();
        end
                
        function CalculateDependents(self,Run_End);
            % Subduction
            if self.Constants.Seafloor.Subduction_Spread==0;
                self.Presents.Seafloor.Subduction_Gauss = 0;
            else
                self.Presents.Seafloor.Subduction_Gauss = (GenerateGaussian(self.Constants.Architecture.Hypsometric_Bin_Midpoints,[self.Constants.Seafloor.Subduction_Spread,-self.Constants.Seafloor.Subduction_Mean]))*self.Constants.Seafloor.Subduction_Risk;
            end
            self.Presents.Seafloor.Subduction_Gauss = (self.Presents.Seafloor.Subduction_Gauss./max(self.Presents.Seafloor.Subduction_Gauss)).*self.Presents.Seafloor.Subduction_Risk;
            
            
            % Outgassing
            Max_Outgassing = self.GetMaxOutgassing(Run_End);
            
            self.Initials.Outgassing_Maximum = Max_Outgassing;
            if self.Constants.Outgassing.Spread==0;
                self.Presents.Outgassing.Gauss = 0;
            else
                self.Presents.Outgassing.Gauss = GenerateGaussian([-self.Constants.Outgassing.Spread*3:self.Constants.Outgassing.Temporal_Resolution:self.Constants.Outgassing.Spread*3],[self.Constants.Outgassing.Spread,0]);
                self.Presents.Outgassing.Gauss = (self.Presents.Outgassing.Gauss/sum(self.Presents.Outgassing.Gauss))';
            end
                
            if isempty([self.Initials.Outgassing]);
                self.Initials.Outgassing = zeros(Max_Outgassing,1);
            elseif numel(self.Initials.Outgassing) == 1;
                self.Initials.Outgassing = self.Initials.Outgassing.*ones(Max_Outgassing,1);
            end
            
            % Weathering
            if numel(self.Constants.Weathering.Silicate_Weathering_Coefficients)==2;
                self.Constants.Weathering.Silicate_Weathering_Coefficients(3) = 0;
            end
            if numel(self.Constants.Weathering.Carbonate_Weathering_Coefficients)==2;
                self.Constants.Weathering.Carbonate_Weathering_Coefficients(3) = 0;
            end
            self.Initials.Silicate_Weathering_Fraction = (self.Constants.Weathering.Silicate_Weathering_Coefficients(1)*exp(self.Constants.Weathering.Silicate_Weathering_Coefficients(2)*self.Initials.Atmosphere_Temperature)+self.Constants.Weathering.Silicate_Weathering_Coefficients(3))/2;
            self.Initials.Carbonate_Weathering_Fraction = (self.Constants.Weathering.Carbonate_Weathering_Coefficients(1)*exp(self.Constants.Weathering.Carbonate_Weathering_Coefficients(2)*self.Initials.Atmosphere_Temperature)+self.Constants.Weathering.Carbonate_Weathering_Coefficients(3))/2;
            
            self.Initials.Conditions(13) = self.Initials.Silicate_Weathering_Fraction;
            self.Initials.Conditions(14) = self.Initials.Carbonate_Weathering_Fraction;

            % Weathering            
            OceanArray = double(self.Presents.Architecture.Hypsometric_Bin_Midpoints<round(self.Initials.Sea_Level));
            
            Silicate_Weathering = (self.Initials.Conditions(12)*self.Initials.Conditions(13));
            Carbonate_Weathering = (1-OceanArray).*(self.Initials.Seafloor.*self.Presents.Weathering.Carbonate_Exposure).*self.Initials.Carbonate_Weathering_Fraction.*self.Presents.Weathering.Carbonate_Weatherability;

            Weathering = (Silicate_Weathering*self.Constants.Weathering.Silicate_Weatherability + Carbonate_Weathering*self.Constants.Weathering.Carbonate_Weatherability);
            
            self.Presents.Phosphate.Riverine_Concentration = ((Silicate_Weathering.*self.Presents.Phosphate.Proportionality_To_Silicate)+(sum(Carbonate_Weathering).*self.Presents.Phosphate.Proportionality_To_Carbonate))./self.Presents.Architecture.Riverine_Volume;
    
            self.Presents.Carbon.Riverine_Carbon = (2*(Silicate_Weathering+sum(Carbonate_Weathering)))./self.Presents.Architecture.Riverine_Volume;
            self.Presents.Carbon.Riverine_Alkalinity =(2*(Silicate_Weathering+sum(Carbonate_Weathering)))./self.Presents.Architecture.Riverine_Volume;

            self.Presents.Carbonate_Chemistry.SetCoefficients();
            self.Presents.Carbonate_Chemistry.Calcium_Initial = self.Constants.Carbonate_Chemistry.Calcium;
            self.Presents.Carbonate_Chemistry.Magnesium_Initial = self.Constants.Carbonate_Chemistry.Magnesium;
            self.Presents.Carbonate_Chemistry.SetCCKs();
    
            % pH
            self.Presents.Carbonate_Chemistry.Solve([],1);
            self.Presents.Carbonate_Chemistry.H_In = pH2H(self.Presents.Carbonate_Chemistry.pH);

            % Lysocline
            self.Presents.Carbonate_Chemistry.Solve_Lysocline([],1);
            self.Presents.Carbonate_Chemistry.Lysocline_In = self.Presents.Carbonate_Chemistry.Lysocline;    
        end
        function Max_Outgassing = GetMaxOutgassing(self,Run_End);
            Max_Outgassing = ceil(((self.Constants.Outgassing.Mean_Lag)+(3.*self.Constants.Outgassing.Spread)+(Run_End))./self.Constants.Outgassing.Temporal_Resolution);
        end
        function SetInitialMaxOutgassing(self,Run_End);
            self.Initials.Outgassing_Maximum = self.GetMaxOutgassing(Run_End);
        end
        
        function AssignConstants(self,Transients_Data);
        % Add constants to Output object
        % Adds the constants to the model object
            % That includes the dimensional matching of values with a 'd'
            % dimension (so two element vectors will become matrices with
            % first dimension size of two).
            
        % ##MAY be a conflict where parameter depth number is needed as
        % this is not propagated with the uniques!
            if ~isempty(Transients_Data);
                Transient_Names = self.Transients.GetNames();
                for Parameter = 1:size(Transient_Names,1);
                    self.Presents.(Transient_Names{Parameter,1}).(Transient_Names{Parameter,2}) = [];
                    self.Presents.(Transient_Names{Parameter,1}).(Transient_Names{Parameter,2})(self.Transients.Matrix{Parameter,4},:) = horzcat(Transients_Data{Parameter,:});
                end
            end
        end
        
        function Load(self,Filename);
            self.Initials.Load(Filename);
            self.Functionals.Load(Filename);
            self.Constants.Load(Filename);
            self.Perturbations.Load(Filename);
            self.Transients.Load(Filename);
            
            self.UpdatePresent();
        end
    end        
end