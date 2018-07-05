classdef Region < matlab.mixin.Copyable
    properties
        Conditions@Condition
        Outputs@Output
        Information@Information
        
        Total_Steps
        Current_Step
        dt
    end
    properties (Hidden = true)
        Dimension_Map
        Data_Names
        Data_Indices
    end
    methods
        % Constructor method
        function self = Region(Conditions)
            % Take input arguments if given
            if nargin~=0;
                self.Conditions = Conditions;
            % Otherwise instantiate a default architecture
            else
                self.Conditions = Condition();
                self.Outputs = Output();
%                 self.Data_Names = {'Atmosphere_CO2','Algae','Phosphate','DIC','Alkalinity'};
            end
            self.Data_Names = {'Atmosphere_CO2';
                              'Algae';
                              'Phosphate';
                              'DIC';
                              'Alkalinity';
                              'Atmosphere_Temperature';
                              'Ocean_Temperature';
                              'Silicate';
                              'Silicate_Weathering_Fraction';
                              'Carbonate_Weathering_Fraction';
                              'Radiation';
                              'Ice';
                              'Sea_Level';
                              'Snow_Line'};
                          
            self.Data_Indices = {1,2,[3,4],[5,6],[7,8],9,[10,11],12,13,14,15,16,17,18,19};
        end
        % Add self method
        function self = AddRegion(self);
            if isempty(self);
                self = Region();
            else
                self = [self,Region()];
            end
        end
                
        %% Add properties
        function AddArchitecture(self,Architecture);
            self.Architectures = [self.Architectures,Architecture];
        end
        function AddCondition(self,Condition);
            self.Conditions = [self.Conditions,Condition];
        end
                
        %% Return Names
        % Specifically goes through Variables which are in cells and
        % returns the names
        function Names = Name(self);
            for n = 1:size(self.Conditions.Variable,1);
                Names{n} = self.Conditions.Variable{n,1}{1};
            end
        end
        
        %% Saving Data
        function SaveData(self,Info,Run_Index,Region_Index);
%             if isstring(Info);
%                 Info = char(Info);
%             end
            FileID = netcdf.open(Info.Output_File,'WRITE');
            
            % Specify start and stride
            Start = [0,0,Region_Index-1,Run_Index-1];
            Count = [1,1,1,1];
            Stride = [1,1,1,1];
            
            DataGrpID = netcdf.inqNcid(FileID,'Data');            
            
            Data_Names = keys(self.Outputs.Data_Size_Map);
            % Loop
            for Data_Index = 1:numel(Data_Names);
                Count(1) = size(self.Outputs.(Data_Names{Data_Index}),1);
                Count(2) = size(self.Outputs.(Data_Names{Data_Index}),2);
                if ~isempty(self.Outputs.(Data_Names{Data_Index}));
                    netcdf.putVar(DataGrpID,netcdf.inqVarID(DataGrpID,Data_Names{Data_Index}),Start,Count,Stride,self.Outputs.(Data_Names{Data_Index}));
                end
            end
            
            netcdf.close(FileID);
        end
        function SaveConstants(self,Info,Region_Index,Run_Index);
            % Open file
            FileID = netcdf.open(Info.Output_File,'WRITE');
            
            % Specify start and stride
            Start = [0,0,Region_Index-1,Run_Index-1];
            Stride = [1,1,1,1];
            
            % Get ID of appropriate group
            ParamGrpID = netcdf.inqNcid(FileID,'Parameters');
            SubGrpIDs = netcdf.inqGrps(ParamGrpID);
            
            for Sub_Group_Index = 1:numel(SubGrpIDs);
                Sub_Group_Name = string(netcdf.inqGrpName(SubGrpIDs(Sub_Group_Index)));
                VarIDs = netcdf.inqVarIDs(SubGrpIDs(Sub_Group_Index));
                for Parameter_Index = 1:numel(VarIDs);
                    Parameter_Name = string(netcdf.inqVar(SubGrpIDs(Sub_Group_Index),VarIDs(Parameter_Index)));
                    
                    if isstring(self.Conditions.Presents.(Sub_Group_Name).(Parameter_Name));
                        Count = [strlength(self.Conditions.Presents.(Sub_Group_Name).(Parameter_Name)),1,1,1];
                        netcdf.putVar(SubGrpIDs(Sub_Group_Index),VarIDs(Parameter_Index),Start,Count,Stride,char(self.Conditions.Presents.(Sub_Group_Name).(Parameter_Name)));
                    elseif ischar(self.Conditions.Presents.(Sub_Group_Name).(Parameter_Name)) || isnumeric(self.Conditions.Presents.(Sub_Group_Name).(Parameter_Name));
                        Count = [size(self.Conditions.Presents.(Sub_Group_Name).(Parameter_Name)),1,1];
                        netcdf.putVar(SubGrpIDs(Sub_Group_Index),VarIDs(Parameter_Index),Start,Count,Stride,self.Conditions.Presents.(Sub_Group_Name).(Parameter_Name));
                    end
                end
            end

            netcdf.close(FileID);
        end
        function SaveTransients(self,Filename,Region_Index,Run_Index);
            % Open file
            FileID = netcdf.open(Filename,'WRITE');
            
            % Specify start and stride
            Start = [0,0,Region_Index-1,Run_Index-1];
            Stride = [1,1,1,1];
            
            % Get ID of appropriate group
            ParamGrpID = netcdf.inqNcid(FileID,'Parameters');
            SubGrpIDs = netcdf.inqGrps(ParamGrpID);
            
            for Sub_Group_Index = 1:numel(SubGrpIDs);
                Sub_Group_Name = string(netcdf.inqGrpName(SubGrpIDs(Sub_Group_Index)));
                VarIDs = netcdf.inqVarIDs(SubGrpIDs(Sub_Group_Index));
                for Parameter_Index = 1:numel(VarIDs);
                    Parameter_Name = string(netcdf.inqVar(SubGrpIDs(Sub_Group_Index),VarIDs(Parameter_Index)));
                    
                    Count = [size(self.Conditions.Presents.(Sub_Group_Name).(Parameter_Name)),1,1];
                    netcdf.putVar(SubGrpIDs(Sub_Group_Index),VarIDs(Parameter_Index),Start,Count,Stride,self.Conditions.Presents.(Sub_Group_Name).(Parameter_Name));
                end
            end
            
            netcdf.close(FileID);
        end
        function SaveAttributes(self,Filename,Version_Number,Version_Codename);
            % Open file
            FileID = netcdf.open(Filename,'WRITE');
            
            % Enter define mode
            netcdf.reDef(FileID);
            
            % Get global ID
            GlobalID = netcdf.getConstant('GLOBAL');
            
            % Save attributes
%             netcdf.putAtt(FileID,GlobalID,'Model',self.Model);
            netcdf.putAtt(FileID,GlobalID,'Version_Number',Version_Number);
            netcdf.putAtt(FileID,GlobalID,'Version_Codename',char(Version_Codename));
            
%             netcdf.putAtt(FileID,GlobalID,'Core',self.Core);
%             netcdf.putAtt(FileID,GlobalID,'Solver',self.Solver);
            
            netcdf.close(FileID);
        end
        function Save(self,Information,Region_Index,Run_Index);
            self.SaveAttributes(Information.Output_File,Information.Version_Number,Information.Version_Codename);
            self.SaveData(Information,Region_Index,Run_Index);
            self.SaveConstants(Information,Region_Index,Run_Index);
%             self.SaveTransients(Filename,Run_Index,Region_Index);
        end
        
        %% Constants
        function ConstNamesClean = GetCleanConstNames(self,Type);
        % Returns constant names with specific names removed
            ConstNames = fieldnames(self.(Type));
            RemovedNames = {'Pressure_Correction','Hypsometric_Interpolation_Matrix','k0_Matrix','k1_Matrix','k2_Matrix','kb_Matrix','kw_Matrix','ksp_cal_Matrix','ksp_arag_Matrix','ks_Matrix'};
            VarNames = self.GetVarNames();
            ConstNamesClean = setdiff(ConstNames,[RemovedNames';[VarNames{:}]']);
        end
        
        %% Replication
        function Replication_Data = MakeReplicationData(self,Run_Data_In);
            for Chunk_Index = 1:numel(Run_Data_In.Chunks);
                Run_Matrix(Chunk_Index,1:6) = [Run_Data_In.Chunks(Chunk_Index).TimeIn,Run_Data_In.Chunks(Chunk_Index).TimeOut];
            end
            Run_Data = Run_Matrix;
            
            Initial_Data = self.Conditions.Initials.Conditions;
            Initial_Seafloor = self.Conditions.Initials.Seafloor;
            Initial_Outgassing = self.Conditions.Initials.Outgassing;
            Replication_Data = {Run_Data,Initial_Data,Initial_Seafloor,Initial_Outgassing};
        end
        
        %% Loading Data
        function Load(self,Filename);
            self.Information.Load(Filename);
            self.Conditions.Load(Filename);
            self.Outputs.Load(Filename);
        end
    end
end