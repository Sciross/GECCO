classdef Initial < matlab.mixin.Copyable
    properties
        Algae
        Phosphate
        Atmosphere_CO2
        DIC
        Alkalinity
        Atmosphere_Temperature
        Ocean_Temperature
        Silicate
        Silicate_Weathering_Fraction
        Carbonate_Weathering_Fraction
        Radiation
        Ice
        Sea_Level
        Snow_Line
        Seafloor
        Outgassing
    end
    properties (Hidden=true)
        Conditions
        Outgassing_End
        Outgassing_Maximum
        Time_End
    end
    methods(Static)
        function Retrieved_Data = LoadIndividualFull(Filename,Individual,Indices,Count);
            % Check against string input (what happens if another type is
            % used?)
            if ~ischar(Individual);
                Individual = char(Individual);
            end
            
            % Deal with the Index            
            FileID = netcdf.open(Filename,'NOWRITE');
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            try
                VarID = netcdf.inqVarID(DataGrpID,Individual);
            catch
                warning(strcat("Parameter '",string(Individual),"' not found"));
                Retrieved_Data = [];
                return;
            end
            [~,~,DimIDs,~] = netcdf.inqVar(DataGrpID,VarID);
            [Dim_Names,Dim_Sizes] = GECCO.DimIDToDim(FileID,DimIDs);
            
            % Process Index
            if nargin<3;
                Indices = {':',':',':',':'};
            elseif numel(Indices)==1;
                Indices = {Indices,Indices,Indices,Indices};                
            end
            
            % Change indices to matrix
            if iscell(Indices);
                for Indices_Index = 1:numel(Indices);
                    if isnumeric(Indices{Indices_Index});
                        if Indices{Indices_Index}<Dim_Sizes(Indices_Index);
                            Start(Indices_Index) = Indices{Indices_Index};
                        else                            
                            netcdf.close(FileID);
                            error("The index was longer than the variable");
                        end
                    else
                        if strcmp(Indices{Indices_Index},':');                    
                            Start(Indices_Index) = 0;
                        elseif strcmp(Indices{Indices_Index},'end');
                            Start(Indices_Index) = Dim_Sizes(Indices_Index)-1;
                        else
                            netcdf.close(FileID);
                            error("The index string was not understood");
                        end                        
                    end                    
                end
            else
                Start = Indices;
            end
            if nargin<4;
                Count = Dim_Sizes-Start;
            elseif any(isnan(Count));
                for Count_Index = 1:numel(Count);
                    if isnan(Count(Count_Index));
                        Count(Count_Index) = Dim_Sizes(Count_Index);
                    end
                end
            end
            
            Retrieved_Data = netcdf.getVar(DataGrpID,VarID,Start,Count);
            netcdf.close(FileID);
        end
        function Retrieved_Data = LoadIndividual(Filename,Individual);
            Retrieved_Data = Initial.LoadIndividualFull(Filename,Individual,[0,0,0,0],[NaN,1,1,1]);
        end
    end
    methods
        function self = Initial();
            if nargin<1;
                self = DefineInitial(self);
            end
        end
        function Deal(self);
            self.Atmosphere_CO2 = self.Conditions(1);
            self.Algae = self.Conditions(2);
            self.Phosphate = self.Conditions(3:4);
            self.DIC = self.Conditions(5:6);
            self.Alkalinity = self.Conditions(7:8);
            self.Atmosphere_Temperature = self.Conditions(9);
            self.Ocean_Temperature = self.Conditions(10:11);
            self.Silicate = self.Conditions(12);
%             self.Carbonate = self.Conditions(13);
            self.Silicate_Weathering_Fraction = self.Conditions(13);
            self.Carbonate_Weathering_Fraction = self.Conditions(14);
            self.Radiation = self.Conditions(15);
            self.Ice = self.Conditions(16);
            self.Sea_Level = self.Conditions(17);
            self.Snow_Line = self.Conditions(18);
        end
        function Undeal(self);
            self.Conditions = [self.Atmosphere_CO2; %1
                               self.Algae; %2
                               self.Phosphate; %3,4
                               self.DIC; %5,6
                               self.Alkalinity; %7,8
                               self.Atmosphere_Temperature; %9
                               self.Ocean_Temperature; %10,11
                               self.Silicate; %12
%                                self.Carbonate; %13
                               self.Silicate_Weathering_Fraction; %13
                               self.Carbonate_Weathering_Fraction; %14
                               self.Radiation; %15
                               self.Ice; %16
                               self.Sea_Level; %17
                               self.Snow_Line]; %18
        end
        function Outgassing_End = CalculateOutgassingEnd(self,Filename);
            FileID = netcdf.open(Filename,'NOWRITE');
            ParamGrpID = netcdf.inqNcid(FileID,'Parameters');
            ParamSubGrpID = netcdf.inqNcid(ParamGrpID,'Outgassing');
            VarID = netcdf.inqVarID(ParamSubGrpID,'Temporal_Resolution');
            Outgassing_Resolution = netcdf.getVar(ParamSubGrpID,VarID);
            netcdf.close(FileID);
            
            % Need end time of model run and outgassing resolution
            Time_End = self.LoadIndividualFull(Filename,'Time',{":","end",":",":"});
            
            Outgassing_End = Time_End./Outgassing_Resolution;
        end
        function SetOutgassingEnd(self,Filename);
            self.Outgassing_End = self.CalculateOutgassingEnd(Filename);
        end
        function PadOutgassing(self);
            if self.Outgassing_Maximum-numel(self.Outgassing((self.Outgassing_End+1):end))>=0;
                self.Outgassing = padarray(self.Outgassing((self.Outgassing_End+1):end),self.Outgassing_Maximum-numel(self.Outgassing((self.Outgassing_End+1):end)),'post');
            else
                self.Outgassing = self.Outgassing((numel(self.Outgassing)-self.Outgassing_Maximum+1):end);
            end
        end
        
        function Load(self,Filename);
            Properties = properties(self);
            for Properties_Index = 1:numel(Properties);
                Property_Data = self.LoadIndividual(Filename,Properties{Properties_Index});
                if ~isempty(Property_Data);
                    self.(Properties{Properties_Index}) = Property_Data;
                end
            end
        end
        function LoadFinal(self,Filename);
            Properties = properties(self);
            for Properties_Index = 1:numel(Properties);
                self.(Properties{Properties_Index}) = self.LoadIndividualFull(Filename,Properties{Properties_Index},{":","end",":",":"});
            end
            self.SetOutgassingEnd(Filename);
%             self.SetOutgassingRequiredEnd();
            self.PadOutgassing();
            
        end
        
        function AddToOutgassing(self,Time_Array,Mean,Spread,Total);
            Gaussian = GenerateGaussian(Time_Array,[Spread,Mean]);
            Scaled_Gaussian = (Gaussian./nansum(Gaussian)).*Total;
            self.Outgassing = self.Outgassing+Scaled_Gaussian';
        end
        function PerformStandardOutgassingPerturbation(self,Time_Array,Carbon_Addition,Perturbation_Time_Centre,Perturbation_Time_Spread);
            if nargin<5;
                Perturbation_Time_Spread = 0.3e6;
                if nargin<4;
                    Perturbation_Time_Centre = 1e6;
                    if nargin<3;
                        Carbon_Addition = 20000; %GtC
                    end
                end
            end
            Carbon_Addition_kg = (Carbon_Addition.*1e9).*1e6;
            Carbon_Addition_mol = Carbon_Addition_kg./12;
            self.AddToOutgassing(Time_Array,Perturbation_Time_Centre,Perturbation_Time_Spread,Carbon_Addition_mol);            
        end
        
    end
    methods(Access = protected)
        function Copy = copyElement(self);
            Copy = Initial();
            Copy_Properties = properties(Copy);
            for Property_Index = 1:numel(Copy_Properties);
                Copy.(Copy_Properties{Property_Index}) = self.(Copy_Properties{Property_Index});
            end
        end
    end
end