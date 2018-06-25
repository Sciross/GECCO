classdef Parameter < matlab.mixin.Copyable
    properties
        Architecture
        Phosphate
        Carbon
        Carbonate_Chemistry
        Seafloor
        Outgassing
        Ice
        Weathering
        Energy        
    end
    properties (Hidden=true);
        DimensionMap
    end
    methods
        function self = Parameter(Empty_Cell_Flag);
            if nargin==0;
                Empty_Cell_Flag = 0;
            end
            self.Architecture = Architecture(Empty_Cell_Flag);
            self.Phosphate = Phosphate(Empty_Cell_Flag);
            self.Carbon = Carbon(Empty_Cell_Flag);
            self.Seafloor = Seafloor(Empty_Cell_Flag);
            self.Outgassing = Outgassing(Empty_Cell_Flag);
            self.Ice = Ice(Empty_Cell_Flag);
            self.Weathering = Weathering(Empty_Cell_Flag);
            self.Energy = Energy(Empty_Cell_Flag);
            self.Carbonate_Chemistry = Carbonate_Chemistry(Empty_Cell_Flag,self.Architecture.Ocean_Midpoints);
        end        
        function MakeDimensionMap(self);
        % Produces a dimensional map of the constants
            % Keys are the fieldnames
%             Keys = fieldnames(self);
            Keys = Condition.GetDottedNames(self);
            % Loop through each key
            for Parameter = 1:numel(Keys);
                % Get the size
                Split_Key = strsplit(Keys{Parameter},'.');
                
                ParameterSize{Parameter} = size(self.(Split_Key{1}).(Split_Key{2}));
                Parameter_Type = class(self.(Split_Key{1}).(Split_Key{2}));
                
                % Assign the 'a' or 'd' dimension
                if strcmp(Parameter_Type,"string") || strcmp(Parameter_Type,"char");
                    Dimension1 = {'u_1'};
                elseif ParameterSize{Parameter}(1)==1;
                    Dimension1 = {'a'};
                elseif ParameterSize{Parameter}(1)==2;
                    Dimension1 = {'d'};
                elseif any(strcmp(Keys{Parameter},{'Architecture.Hypsometry','Architecture.Cumulative_Hypsometry','Architecture.Hypsometric_Bin_Midpoints','Seafloor.Subduction_Rate','Seafloor.Subduction_Gauss','Seafloor.Uplift_Rate'}));
                    Dimension1 = {'s'};
                elseif strcmp(Keys{Parameter},{'Seafloor.Core_Depths'});
                    Dimension1 = {'c'};
                elseif sum(strcmp(Keys{Parameter},{'Outgassing.Gauss'}));
                    Dimension1 = {'g'};
                elseif ParameterSize{Parameter}(1)==0;
                    Dimension1 = {'N'};
                else
                    Dimension1 = {['k_',num2str(ParameterSize{Parameter}(1))]};
                end
                
                % Assign constant, special cases covered by _VAL
                if strcmp(Parameter_Type,"string") || strcmp(Parameter_Type,"char");
                    Dimension2 = {'u_2'};
                elseif strcmp(Keys{Parameter},'Carbon.PIC_Burial');
                    Dimension2 = {'t'};
                elseif ParameterSize{Parameter}(2)==1;
                    Dimension2 = {'k'};
                elseif ParameterSize{Parameter}(1)==0 || contains(Keys{Parameter},"Coefficient");
                    Dimension2 = {'N'};
                else
                    Dimension2 = {['k_',num2str(ParameterSize{Parameter}(2))]};
                end
                
                % Third dimension is the number of regions
                Dimension3 = 'r'; % {numel(self.Conditions.Constant)};
                
                Dimension4 = 'R';
                
                % Concatenate the dimensional values
                Values{Parameter} = [Dimension1,Dimension2,Dimension3,Dimension4];
                Valid_Keys{Parameter} = char(strrep(Keys{Parameter},".","_"));
            end
            % Create the map object
            self.DimensionMap = containers.Map(Valid_Keys,Values);
        end               
        function UpdateDimensionMap(self,Variables);
        % Updates the dimensional map to include variables
            % Loop through each Variable and assign the second dimension as
            % 't' instead of 'k'
            for Parameter = 1:size(Variables,1);
                Underscore_Name = [Variables{Parameter,2},'_',Variables{Parameter,3}];
                Dimensions = self.DimensionMap(Underscore_Name);
                if numel(self.(Variables{Parameter,2}).(Variables{Parameter,3}))<=2;
                    Dimensions{2} = 't';
                else
                    Dimensions{2} = 'k';
                end
                self.DimensionMap(Underscore_Name) = Dimensions;
            end
        end
        function Load(self,Filename,Run_Index);
            if nargin<3;
                Run_Index = ":";
            end
            if strcmp(class(self),"Parameter");
                self.Architecture.Load(Filename,Run_Index);
                self.Phosphate.Load(Filename,Run_Index);
                self.Carbon.Load(Filename,Run_Index);
                self.Carbonate_Chemistry.Load(Filename,Run_Index);
                self.Seafloor.Load(Filename,Run_Index);
                self.Outgassing.Load(Filename,Run_Index);
                self.Ice.Load(Filename,Run_Index);
                self.Weathering.Load(Filename,Run_Index);
                self.Energy.Load(Filename,Run_Index);
            elseif strcmp(class(self),"Perturbation");
                self.Architecture.LoadPerturbations(Filename,Run_Index);
                self.Phosphate.LoadPerturbations(Filename,Run_Index);
                self.Carbon.LoadPerturbations(Filename,Run_Index);
                self.Carbonate_Chemistry.LoadPerturbations(Filename,Run_Index);
                self.Seafloor.LoadPerturbations(Filename,Run_Index);
                self.Outgassing.LoadPerturbations(Filename,Run_Index);
                self.Ice.LoadPerturbations(Filename,Run_Index);
                self.Weathering.LoadPerturbations(Filename,Run_Index);
                self.Energy.LoadPerturbations(Filename,Run_Index);
                self.Output.LoadPerturbations(Filename,Run_Index);
            elseif strcmp(class(self),"Transient");
                self.Architecture.LoadTransients(Filename,Run_Index);
                self.Phosphate.LoadTransients(Filename,Run_Index);
                self.Carbon.LoadTransients(Filename,Run_Index);
                self.Carbonate_Chemistry.LoadTransients(Filename,Run_Index);
                self.Seafloor.LoadTransients(Filename,Run_Index);
                self.Outgassing.LoadTransients(Filename,Run_Index);
                self.Ice.LoadTransients(Filename,Run_Index);
                self.Weathering.LoadTransients(Filename,Run_Index);
                self.Energy.LoadTransients(Filename,Run_Index);
            end
        end
    end
end