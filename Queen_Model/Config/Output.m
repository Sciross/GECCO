classdef Output < matlab.mixin.Copyable & ParameterLoad
    properties
        Time
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
        Lysocline
        Carbonate_Total
        Carbonate_Exposed
        pH
        Cores
    end
    properties (Hidden=true)
        Data_Size_Map
    end
    methods
        function self = Output();
            Sizes = [1,1,2,1,2,2,1,2,1,1,1,1,1,1,1,NaN,NaN,1,1,1,2,NaN];
            self.Data_Size_Map = containers.Map(properties(self),Sizes);
        end
        function StartSave(self,Filename,DimensionSizes,DimensionMap);
            GECCO.PrepareNetCDF(Filename,DimensionSizes,DimensionMap);
        end
        function Load(self,Filename);
            Properties = properties(self);
            for Properties_Index = 1:numel(Properties);
                self.(Properties{Properties_Index}) = self.LoadIndividual(Filename,Properties{Properties_Index});
            end
        end
        function LoadFinal(self,Filename);            
            Properties = properties(self);
            for Properties_Index = 1:numel(Properties);
                self.(Properties{Properties_Index}) = self.LoadIndividual(Filename,Properties{Properties_Index},"end");
            end
        end
        function Retrieved_Data = LoadIndividual(self,Filename,Individual,Indices);
            % Check against string input (what happens if another type is
            % used?)
            if ~ischar(Individual);
                Individual = char(Individual);
            end
            
            % Deal with the Index            
            FileID = netcdf.open(Filename,'NOWRITE');
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            VarID = netcdf.inqVarID(DataGrpID,Individual);
            [~,~,DimIDs,~] = netcdf.inqVar(DataGrpID,VarID);
            [DimNames,DimSizes] = GECCO.DimIDToDim(FileID,DimIDs);
            
            if nargin<4;
                Indices = {':',':',':',':'};
            elseif numel(Indices)==1;
                Indices = {Indices,Indices,Indices,Indices};                
            end
            
            % Change indices to matrix
            if iscell(Indices);
                for Indices_Index = 1:numel(Indices);
                    if isnumeric(Indices{Indices_Index});
                        if Indices<DimSizes(Indices_Index);
                            Start(Indices_Index) = Indices{Indices_Index};
                        else                            
                            netcdf.close(FileID);
                            error("The index was longer than the variable");
                        end
                    else
                        if strcmp(Indices{Indices_Index},':');                    
                            Start(Indices_Index) = 0;
                        elseif strcmp(Indices{Indices_Index},'end');
                            Start(Indices_Index) = DimSizes(Indices_Index)-1;
                        else
                            netcdf.close(FileID);
                            error("The index string was not understood");
                        end                        
                    end                    
                end
            end
            Count = DimSizes-Start;
            
            Retrieved_Data = netcdf.getVar(DataGrpID,VarID,Start,Count);
            netcdf.close(FileID);
        end
    end
end