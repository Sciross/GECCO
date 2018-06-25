classdef GECCO < handle
    properties
        Runs@Run
        Information@Information
    end
    properties (Hidden=true)
        ValidatedFlag = 0;
        UsedGUIFlag = 0;
        FileExists = 0;
        RunTable
        InitTable
        InstalledModels
        AvailableCores
        ModelDirectory
        ShouldSaveFlag = 1;
        SaveToSameFileFlag = 1;
        SaveToRunFilesFlag = 0;
    end
    methods(Static)
        function Flag = CheckFileExists(Filepath);
            if nargin>0 && ~strcmp(Filepath,"");
                Flag = exist(Filepath,'file');
            else
                error("Please provide a filename");
            end
        end
        function DimIDs = DimToDimID(FileID,Dims);
            for Dim_Index = 1:numel(Dims);
                DimIDs(Dim_Index) = netcdf.inqDimID(FileID,Dims{Dim_Index});
            end
        end
        function [DimNames,DimSizes] = DimIDToDim(FileID,DimIDs);
            for Dim_Index = 1:numel(DimIDs);
                [DimNames{Dim_Index},DimSizes(Dim_Index)] = netcdf.inqDim(FileID,DimIDs(Dim_Index));
            end
        end
            
        function CreateFile(Filename);
            if ~ischar(Filename);
                Filename = char(Filename);
            end
            NETCDF4 = netcdf.getConstant('NETCDF4');
            NOCLOBBER = netcdf.getConstant('NC_NOCLOBBER');
            CreateMode = bitor(NETCDF4,NOCLOBBER);
            FileID = netcdf.create(Filename,CreateMode);
            netcdf.close(FileID);
        end
        
        function AddModelAttribute(Filename,Model);
            % Open file
            FileID = netcdf.open(Filename,'WRITE');
            
            % Enter define mode
            netcdf.reDef(FileID);
            
            % Get global ID
            GlobalID = netcdf.getConstant('GLOBAL');
            
            % Save attributes
            netcdf.putAtt(FileID,GlobalID,'Model',char(Model));
            
            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end        
        function AddUnlimitedDimensions(Filename);
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            Dim_u1 = {'u_1',100};
            Dim_u2 = {'u_2',500};
            
            
            netcdf.defDim(FileID,Dim_u1{1},Dim_u1{2});
            netcdf.defDim(FileID,Dim_u2{1},Dim_u2{2});
            
            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end
        
        function AddDataGroup(Filename);
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);            
            
            DataGrpID = netcdf.defGrp(FileID,'Data');
            
            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end
        function DefineDataDimensions(Filename,Values);
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            % Runs
            DimR = {'R',Values(1)};
            netcdf.defDim(FileID,DimR{1},DimR{2});
            
            % Regions
            Dimr = {'r',1};
            netcdf.defDim(FileID,Dimr{1},Dimr{2});            
            
            % Time
            Dimt = {'t',Values(2)};
            netcdf.defDim(FileID,Dimt{1},Dimt{2});
            
            % Single Depth
            Dima = {'a',1};
            netcdf.defDim(FileID,Dima{1},Dima{2});
            
            % Double Depth
            Dimd = {'d',2};
            netcdf.defDim(FileID,Dimd{1},Dimd{2});
            
            % Seafloor
            Dims = {'s',Values(3)};
            netcdf.defDim(FileID,Dims{1},Dims{2});
            
            % Carbonate
            Dimc = {'c',Values(4)};
            netcdf.defDim(FileID,Dimc{1},Dimc{2});
            
            % Outgassing
            Dimm = {'m',Values(5)};
            netcdf.defDim(FileID,Dimm{1},Dimm{2});
            
            % Gauss
            Dimg = {'g',Values(6)};
            netcdf.defDim(FileID,Dimg{1},Dimg{2});
            
            % Single Constant
            Dimk = {'k',1};
            netcdf.defDim(FileID,Dimk{1},Dimk{2});
            
            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end
        function DefineData(Filename,Data_Names,Data_Size_Map);
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);            
            
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            CurrentDims = {'a','t','r','R'};
            for Data_Names_Index = 1:numel(Data_Names);
                Data_Size = Data_Size_Map(Data_Names{Data_Names_Index});
                CurrentDims{2} = 't';
                if Data_Size==1;
                    CurrentDims{1} = 'a';
                elseif Data_Size==2;
                    CurrentDims{1} = 'd';
                elseif isnan(Data_Size);
                    if strcmp(Data_Names{Data_Names_Index},'Seafloor');
                        CurrentDims{1} = 's';
                        CurrentDims{2} = 'k';
                    elseif strcmp(Data_Names{Data_Names_Index},'Outgassing');
                        CurrentDims{1} = 'm';
                        CurrentDims{2} = 'k';
                    elseif strcmp(Data_Names{Data_Names_Index},'Cores');
                        CurrentDims{1} = 'c';
                        CurrentDims{2} = 'k';
                    end

                end
                VarID = netcdf.defVar(DataGrpID,Data_Names{Data_Names_Index},'double',GECCO.DimToDimID(FileID,CurrentDims));
                netcdf.defVarFill(DataGrpID,VarID,false,NaN);
            end
            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end
        
        function AddParameterGroup(Filename,ParamGroupNames);   
            FileID = netcdf.open(Filename,'WRITE');     
            netcdf.reDef(FileID);
            
            ParamGrpID = netcdf.defGrp(FileID,'Parameters');
            for Param_Index = 1:numel(ParamGroupNames);
                netcdf.defGrp(ParamGrpID,char(ParamGroupNames(Param_Index)));
            end
            
            netcdf.endDef(FileID);
            netcdf.close(FileID);            
        end
        function DefineParameterDimensions(Filename);
            % Values = {Runs,Max t's,Max Subduction
            % (seafloor?),Cores,Outgassing_Gauss,Outgassing
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            % Constants
            Dimk_6 = {'k_6',6};
            Dimk_13 = {'k_13',13};
            
            netcdf.defDim(FileID,Dimk_6{1},Dimk_6{2});
            netcdf.defDim(FileID,Dimk_13{1},Dimk_13{2});
            
            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end
        function DefineParameters(Filename,Parameter_Group_Names,Parameter_Names,Dimension_Map);
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            ParamGrpID = netcdf.inqNcid(FileID,'Parameters');
            for Param_Index = 1:numel(Parameter_Group_Names);
                ParamSubGrpIDs(Param_Index) = netcdf.inqNcid(ParamGrpID,char(Parameter_Group_Names(Param_Index)));
            end
            
            for Param_Group_Index = 1:numel(Parameter_Group_Names);
                for Param_Index = 1:numel(Parameter_Names{Param_Group_Index});
                    CurrentDims = Dimension_Map(char(strjoin([Parameter_Group_Names(Param_Group_Index),Parameter_Names{Param_Group_Index}(Param_Index)],'_')));
                    if ~any(strcmp(CurrentDims,"N")) && ~contains(Parameter_Names{Param_Group_Index}(Param_Index),"_Matrix");
                        if strcmp(CurrentDims{1},"u_1");
                            ParamSubGrpID = netcdf.inqNcid(ParamGrpID,char(Parameter_Group_Names(Param_Group_Index)));
                            VarID = netcdf.defVar(ParamSubGrpID,char(Parameter_Names{Param_Group_Index}(Param_Index)),'char',GECCO.DimToDimID(FileID,CurrentDims));
%                             netcdf.defVarFill(ParamSubGrpID,VarID,false,NaN);
                        else
                            ParamSubGrpID = netcdf.inqNcid(ParamGrpID,char(Parameter_Group_Names(Param_Group_Index)));
                            VarID = netcdf.defVar(ParamSubGrpID,char(Parameter_Names{Param_Group_Index}(Param_Index)),'double',GECCO.DimToDimID(FileID,CurrentDims));
                            netcdf.defVarFill(ParamSubGrpID,VarID,false,NaN);
                        end
                    end
                end
            end            
                   
            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end
        
        function AddReplicationGroup(Filename);
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            RepGrpID = netcdf.defGrp(FileID,'Replication');
            
            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end
        function DefineReplicationDimensions(Filename,Replication_Data);
            Run_Stuff = Replication_Data{1};
            Initial_Stuff = Replication_Data{2};
            
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            Dim_r1 = {'c_1',size(Run_Stuff,1)};
            Dim_r2 = {'c_2',size(Run_Stuff,2)};
            
            netcdf.defDim(FileID,Dim_r1{1},Dim_r1{2});
            netcdf.defDim(FileID,Dim_r2{1},Dim_r2{2});
            
            Dim_i2 = {'i_2',numel(Initial_Stuff)};
            netcdf.defDim(FileID,Dim_i2{1},Dim_i2{2});
            
            Dim_t0 = {'t_0',1};
            netcdf.defDim(FileID,Dim_t0{1},Dim_t0{2});
            
            
            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end
        function DefineReplicationVariables(Filename);
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            RepGrpID = netcdf.inqNcid(FileID,'Replication');
            
            CurrentDims = {'c_1','c_2','r','R'};
            netcdf.defVar(RepGrpID,'Run_Matrix','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2})]);
            
            CurrentDims = {'i_2','t_0','r','R'};
            netcdf.defVar(RepGrpID,'Initial_Matrix','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2})]);
            
            CurrentDims = {'s','t_0','r','R'};
            netcdf.defVar(RepGrpID,'Initial_Seafloor','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2})]);
  
            CurrentDims = {'m','t_0','r','R'};
            netcdf.defVar(RepGrpID,'Initial_Outgassing','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2})]);

            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end
        function AddReplicatoryData(Filename,Replication_Data);
            FileID = netcdf.open(Filename,'WRITE');
            RepGrpID = netcdf.inqNcid(FileID,'Replication');
            
            Run_MatrixID = netcdf.inqVarID(RepGrpID,'Run_Matrix');
            netcdf.putVar(RepGrpID,Run_MatrixID,Replication_Data{1});
            
            Init_MatrixID = netcdf.inqVarID(RepGrpID,'Initial_Matrix');
            netcdf.putVar(RepGrpID,Init_MatrixID,Replication_Data{2});
            
            Init_SeafloorID = netcdf.inqVarID(RepGrpID,'Initial_Seafloor');
            Initial_Seafloor = Replication_Data{3};
            netcdf.putVar(RepGrpID,Init_SeafloorID,Initial_Seafloor);
            
            Init_OutgassingID = netcdf.inqVarID(RepGrpID,'Initial_Outgassing');
            Initial_Outgassing = Replication_Data{4};
            netcdf.putVar(RepGrpID,Init_OutgassingID,Initial_Outgassing);
            
            netcdf.close(FileID);
        end
        
        
        function AddPerturbationsGroup(Filename,ParamGroupNames);
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            PertGrpID = netcdf.defGrp(FileID,'Perturbations');            
            for Param_Index = 1:numel(ParamGroupNames);
                netcdf.defGrp(PertGrpID,char(ParamGroupNames(Param_Index)));
            end
            
            netcdf.defGrp(PertGrpID,'Output');
            
            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end
        function DefinePerturbations(Filename,Perturbation_Matrices);
            FileID = netcdf.open(Filename,'WRITE');            
            
            PertGrpID = netcdf.inqNcid(FileID,'Perturbations');
            for Run_Index = 1:numel(Perturbation_Matrices);
                for Perturbation_Index = 1:size(Perturbation_Matrices{Run_Index},1);                    
                    VarGrpID = netcdf.inqNcid(PertGrpID,Perturbation_Matrices{Run_Index}{Perturbation_Index,3});
                    
                    % First define the variable  
                    CurrentDims = {'u_1','u_2','r','R'};
                    netcdf.reDef(FileID);
                    VarID = netcdf.defVar(VarGrpID,[Perturbation_Matrices{Run_Index}{Perturbation_Index,4}],'char',GECCO.DimToDimID(FileID,CurrentDims));
                    netcdf.endDef(FileID);
                    
                    Perturbation_Char = GECCO.CharacterifyCells(Perturbation_Matrices{Run_Index}(Perturbation_Index,:));
                    Perturbation_Required = Perturbation_Char([1,5,6]);
                    Perturbation_Joined = join(Perturbation_Required,'\t');
                    Start = [0,0,0,Run_Index-1];
                    Count = [1,numel(Perturbation_Joined{1}),1,1];
                    netcdf.putVar(VarGrpID,VarID,Start,Count,Perturbation_Joined{1});
                end
            end
            
            netcdf.close(FileID);
        end
        
        function AddTransientsGroup(Filename,ParamGroupNames);
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            TransGrpID = netcdf.defGrp(FileID,'Transients');            
            for Param_Index = 1:numel(ParamGroupNames);
                netcdf.defGrp(TransGrpID,char(ParamGroupNames(Param_Index)));
            end
            
            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end
        function DefineTransients(Filename,Transient_Matrices);
            FileID = netcdf.open(Filename,'WRITE');            
            
            TransGrpID = netcdf.inqNcid(FileID,'Transients');
            for Run_Index = 1:numel(Transient_Matrices);
                for Transient_Index = 1:size(Transient_Matrices{Run_Index},1);                    
                    VarGrpID = netcdf.inqNcid(TransGrpID,Transient_Matrices{Run_Index}{Transient_Index,2});
                    
                    % First define the variable  
                    CurrentDims = {'u_1','u_2','r','R'};
                    netcdf.reDef(FileID);
                    VarID = netcdf.defVar(VarGrpID,[Transient_Matrices{Run_Index}{Transient_Index,3}],'char',GECCO.DimToDimID(FileID,CurrentDims));
                    netcdf.endDef(FileID);
                    
                    Transient_Char = GECCO.CharacterifyCells(Transient_Matrices{Run_Index}(Transient_Index,:));
                    Transient_Required = Transient_Char([1,4,5]);
                    Transient_Joined = join(Transient_Required,'\t');
                    Start = [0,0,0,Run_Index-1];
                    Count = [1,numel(Transient_Joined{1}),1,1];
                    netcdf.putVar(VarGrpID,VarID,Start,Count,Transient_Joined{1});
                end
            end
            
            netcdf.close(FileID);
        end        
        
        function AddFunctionalsGroup(Filename);
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            FuncGrpID = netcdf.defGrp(FileID,'Functionals');
            
            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end
        function DefineFunctionals(Filename,Run_Number,CoreSolver);
            FileID = netcdf.open(Filename,'WRITE');            
            
            FuncGrpID = netcdf.inqNcid(FileID,'Functionals');
            for Run_Index = 1:numel(Run_Number);                  
                    % First define the variable  
                    CurrentDims = {'k','u_2','r','R'};
                    netcdf.reDef(FileID);
                    CoreVarID = netcdf.defVar(FuncGrpID,'Core','char',GECCO.DimToDimID(FileID,CurrentDims));
                    SolverVarID = netcdf.defVar(FuncGrpID,'Solver','char',GECCO.DimToDimID(FileID,CurrentDims));
                    netcdf.endDef(FileID);
                    
                   
                    Start = [0,0,0,Run_Index-1];
                    Count = [1,numel(CoreSolver{1}),1,1];
                    netcdf.putVar(FuncGrpID,CoreVarID,Start,Count,CoreSolver{1});
                    Count = [1,numel(CoreSolver{2}),1,1];
                    netcdf.putVar(FuncGrpID,SolverVarID,Start,Count,CoreSolver{2});
            end
            
            netcdf.close(FileID);
        end    
        
        function PrepareNetCDF(Filename,Model,Data_Names,Data_Sizes,Data_Size_Map,Parameter_Group_Names,Parameter_Names,Dimension_Map,Transient_Matrices,Perturbation_Matrices,Replication_Data,CoreSolver);
            GECCO.CreateFile(Filename);            
            GECCO.AddModelAttribute(Filename,Model);
            GECCO.AddUnlimitedDimensions(Filename);
            
            GECCO.AddDataGroup(Filename);
            GECCO.DefineDataDimensions(Filename,Data_Sizes);
            GECCO.DefineData(Filename,Data_Names,Data_Size_Map);
            
            GECCO.AddParameterGroup(Filename,Parameter_Group_Names);
            GECCO.DefineParameterDimensions(Filename);
            GECCO.DefineParameters(Filename,Parameter_Group_Names,Parameter_Names,Dimension_Map);
            
            GECCO.AddPerturbationsGroup(Filename,Parameter_Group_Names);
            GECCO.DefinePerturbations(Filename,Perturbation_Matrices);
            
            GECCO.AddTransientsGroup(Filename,Parameter_Group_Names);
            GECCO.DefineTransients(Filename,Transient_Matrices);
            
            GECCO.AddFunctionalsGroup(Filename);
            GECCO.DefineFunctionals(Filename,Data_Sizes(1),CoreSolver);
            
            GECCO.AddReplicationGroup(Filename);
            GECCO.DefineReplicationDimensions(Filename,Replication_Data);
            GECCO.DefineReplicationVariables(Filename);
            GECCO.AddReplicatoryData(Filename,Replication_Data);
        end

        function Character_Cells = CharacterifyCells(Cells);
            Character_Cells = cell(size(Cells));
            for Cell_Index = 1:numel(Cells);
                if ischar(Cells{Cell_Index});
                    Character_Cells{Cell_Index} = Cells{Cell_Index};                    
                elseif isnumeric(Cells{Cell_Index});
                    Character_Cells{Cell_Index} = char(num2str(Cells{Cell_Index}));
                else
                    Character_Cells{Cell_Index} = char(Cells{Cell_Index});
                end
            end
        end
        
        %% Loading Data
        function DataIDs = GetFileDataIDs(Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            DataIDs = netcdf.inqVarIDs(DataGrpID);    
            netcdf.close(FileID);
        end
        function DataNames = GetDataNames(Filename);
            DataIDs = GECCO.GetFileDataIDs(Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            for DataNumber = 1:numel(DataIDs);
                [DataNames{DataNumber},~,~,~] = netcdf.inqVar(DataGrpID,DataIDs(DataNumber));
            end
            netcdf.close(FileID);
        end
        function Time = LoadTime(Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            TimeID = netcdf.inqVarID(DataGrpID,'Time');
            Time = netcdf.getVar(DataGrpID,TimeID);
            netcdf.close(FileID);
        end
        function Data = LoadData(Filename,DataNames);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            Data = [];
            for DataNumber = 1:numel(DataNames);
                DataID = netcdf.inqVarID(DataGrpID,DataNames{DataNumber});
                DataCell{DataNumber} = netcdf.getVar(DataGrpID,DataID);
            end
            Data =  vertcat(DataCell{:});
            netcdf.close(FileID);
        end
        function Lysocline = LoadLysocline(Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            LysID = netcdf.inqVarID(DataGrpID,'Lysocline');
            Lysocline = netcdf.getVar(DataGrpID,LysID); 
            netcdf.close(FileID);
        end
        function Seafloor = LoadSeafloor(Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            SeafloorID = netcdf.inqVarID(DataGrpID,'Seafloor');
            Seafloor = netcdf.getVar(DataGrpID,SeafloorID);
            netcdf.close(FileID);
        end
        function SeafloorTotal = LoadSeafloorTotal(Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');            
            SeafloorTotalID = netcdf.inqVarID(DataGrpID,'Seafloor_Total');            
            SeafloorTotal = netcdf.getVar(DataGrpID,SeafloorTotalID);            
            netcdf.close(FileID);
        end
        function PICBurial = LoadPICBurial(Filename);
            FileID = netcdf.open(Filename);
            ConstGrpID = netcdf.inqNcid(FileID,'Constants');
            PICBurialID = netcdf.inqVarID(ConstGrpID,'PIC_Burial');
            PICBurial = netcdf.getVar(ConstGrpID,PICBurialID);
            netcdf.close(FileID);
        end
        function Carbonate_Surface_Sediment_Lock = LoadLock(Filename);
            FileID = netcdf.open(Filename);
            ConstGrpID = netcdf.inqNcid(FileID,'Constants');
            LockID = netcdf.inqVarID(ConstGrpID,'Carbonate_Surface_Sediment_Lock');
            Carbonate_Surface_Sediment_Lock = netcdf.getVar(ConstGrpID,LockID);
            netcdf.close(FileID);
        end
        function Cores = LoadCores(Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            CoresID = netcdf.inqVarID(DataGrpID,'Cores');
            Cores = netcdf.getVar(DataGrpID,CoresID);
            netcdf.close(FileID);
        end
        function Outgassing = LoadOutgassing(Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            OutgassingID = netcdf.inqVarID(DataGrpID,'Outgassing');
            Outgassing = netcdf.getVar(DataGrpID,OutgassingID);
            netcdf.close(FileID);
        end
        
    end
    methods
        function self = GECCO();
            self.AddRun();
            self.Information = Information();
        end
        function AddRun(self);
            self.Runs = self.Runs.AddRun();
        end

        %%
        function Values = GetDimensionSizes(self);
            Values(1) = numel(self.Runs);
            Values(2) = max(self.GetOutputTimestepCount());
            Values(3) = max(self.GetSeafloorSize());
            Values(4) = max(self.GetCoreDepthSize());
            Values(5) = max(self.GetOutgassingSize());
            Values(6) = max(self.GetOutgassingGaussianSize());
        end
        function MakeDimensionMap(self);
            for RunIndex = 1:numel(self.Runs);
                self.Runs(RunIndex).Regions(1).Conditions.Presents.MakeDimensionMap();
                self.Runs(RunIndex).Regions(1).Conditions.Presents.UpdateDimensionMap(self.Runs(RunIndex).Regions(1).Conditions.Transients.Matrix);
            end
        end
        function MaximumDimensionSizes = GetMaximumDimensionSizes(self);
            for Run_Index = 1:numel(self.Runs);
                Sizes(1,:) = self.GetDimensionSizes();
            end
            MaximumDimensionSizes = max(Sizes,1);
%             Keys = keys(Maps{1});
%             for Run_Index = 1:numel(self.Runs);
%                 for Key_Index = 1:numel(Keys);
%                     Size{Run_Index,Key_Index} = size(Maps{Run_Index}(Keys{Key_Index}));
%                 end
%             end
        end
        
        function SeafloorSize = GetSeafloorSize(self);
            for Run_Index = 1:numel(self.Runs);
                SeafloorSize(Run_Index) = self.Runs(Run_Index).Regions(1).Conditions.GetSizeOf("Constants","Architecture","Hypsometric_Bin_Midpoints");
            end
        end
        function CoreDepthSize = GetCoreDepthSize(self);
            for Run_Index = 1:numel(self.Runs);
                CoreDepthSize(Run_Index) = self.Runs(Run_Index).Regions(1).Conditions.GetSizeOf("Constants","Seafloor","Core_Depths");
            end
        end
        function OutgassingSize = GetOutgassingSize(self);
            for Run_Index = 1:numel(self.Runs);
                OutgassingSize(Run_Index) = self.Runs(Run_Index).Regions(1).Conditions.GetSizeOf("Initials","Outgassing");;
            end
        end
        function OutgassingGaussianSize = GetOutgassingGaussianSize(self);
            for Run_Index = 1:numel(self.Runs);
                OutgassingGaussianSize(Run_Index) = self.Runs(Run_Index).Regions(1).Conditions.GetSizeOf("Presents","Outgassing","Gauss");
            end
        end
        function Timestep = GetTimestepCount(self);
            for Run_Index = 1:numel(self.Runs);
                Timestep(Run_Index) = self.Runs(Run_Index).GetTimestepCount();
            end
        end
        function Timestep = GetOutputTimestepCount(self);
            for Run_Index = 1:numel(self.Runs);
                Timestep(Run_Index) = self.Runs(Run_Index).GetOutputTimestepCount();
            end
        end
        
        function Validate(self,Gui);
            self.ValidatedFlag = 0;
            Max_Outgassing_Tracked = self.Runs(1).Regions(1).Conditions.GetMaxOutgassing(self.Runs(end).Chunks(end).TimeIn(2));
            Initial_Outgassing_Length = self.Runs(1).Regions(1).Conditions.GetSizeOf("Initials","Outgassing");
            NoRunsFlag = 0;
            OutgassingLengthWrongFlag = 0;
            if numel(self.Runs)==0;
                NoRunsFlag = 1;
                if self.UsedGUIFlag;
                    Gui.UpdateLogBox("No run details provided");
                end
            elseif sum(Max_Outgassing_Tracked==Initial_Outgassing_Length | Initial_Outgassing_Length==0 | Initial_Outgassing_Length==1 | Initial_Outgassing_Length==2)==0;
                OutgassingLengthWrongFlag = 1;
                if self.UsedGUIFlag;
                    Gui.UpdateLogBox(strcat("Initial Outgassing array is the wrong length, should be...",num2str(Max_Outgassing_Tracked)," elements"));
                end
            end
            
            [SameFileFlag,RunFilesFlag,RegionFilesFlag] = self.ValidateSaveFlags(Gui);
            
            Flags = [NoRunsFlag,OutgassingLengthWrongFlag,SameFileFlag,RunFilesFlag,RegionFilesFlag];
            if any(Flags);
                self.ValidatedFlag = 0;
            else            
                self.ValidatedFlag = 1;
            end
        end
        function ValidateRuns(self,Gui);
            for RunIndex = 1:numel(self.Runs);
                for ChunkIndex = 1:numel(self.Runs(RunIndex).Chunks);
                    if ChunkIndex == numel(self.Runs(RunIndex).Chunks);
                        break;
                    else
                        TimeOutEnd = self.Runs(RunIndex).Chunks(ChunkIndex).TimeOut(2);
                        TimeOutStart = self.Runs(RunIndex).Chunks(ChunkIndex+1).TimeOut(1);
                        
                        if TimeOutStart~=TimeOutEnd;
                            self.ValidatedFlag = 0;
                            
                            if self.UsedGUIFlag;
                                GUI.UpdateLogBox(["The chunks in Run ",num2str(RunIndex)," are not consecutive"]);
                            end
                        end
                    end
                end
            end
        end        
        function [SameFileFlag,RunFilesFlag,RegionFilesFlag] = ValidateSaveFlags(self,Gui)   
            SameFileFlag = 0;
            RunFilesFlag = 0;
            RegionFilesFlag = 0;
            % Whole file
            if self.ShouldSaveFlag;
                if self.SaveToSameFileFlag;
                    if strcmp(self.Information.OutputFile,"");
                        SameFileFlag = 1;
                        if self.UsedGUIFlag;
                            Gui.UpdateLogBox("Save to same file output file is empty");
                        end
                    end
                end
                % Runs
                if self.SaveToRunFilesFlag;
                    for Run_Index=1:numel(self.Runs);
                        if strcmp(self.Runs(Run_Index).Information.OutputFile,"");
                            RunFilesFlag = 1;
                            if self.UsedGUIFlag;
                                Gui.UpdateLogBox("Save to run files output file is empty");
                            end
                        end
                    end
                end
%                 if all([self.SaveToSameFileFlag,self.SaveToRunFilesFlag,self.SaveToRegionFilesFlag]);
%                     self.ShouldSaveFlag = 0;
%                 end
            end
        end

        
        %% Run
        function RunModel(self,Gui);
            self.MakeReplicationData();
            self.ParseTransientData(Gui);
            self.ParsePerturbationData(Gui);
            
            self.ShouldSaveFlag = any([self.SaveToSameFileFlag,self.SaveToRunFilesFlag]);
            self.Information.SortOutFilepath();        
            self.Validate(Gui);
            for Run_Index = 1:numel(self.Runs);
                RunsValidatedFlags(Run_Index) = self.Runs(Run_Index).Validate();
            end
                        
            self.ValidatedFlag = self.ValidatedFlag && all(RunsValidatedFlags);
            
            if self.ValidatedFlag;
                self.Runs.Regions.Conditions.Constants.Carbonate_Chemistry.SolverToHandle();
                self.Runs.Regions.Conditions.Constants.Carbonate_Chemistry.LysoclineSolverToHandle();
                profile on;
                if self.UsedGUIFlag;
                    Gui.ColourBox.BackgroundColor = [1,1,0.5];
                    drawnow;
                end
                
                self.DeleteExistingFile();
                for Run_Index = 1:numel(self.Runs);
                    self.Runs(Run_Index).Regions(1).Outputs = Output();
                    self.Runs(Run_Index).Regions(1).Conditions.UpdatePresent();
                    self.Runs(Run_Index).Regions(1).Conditions.CalculateDependents(self.Runs(end).Chunks(end).TimeIn(2));
                end
                
                DateTime(1) = datetime('now');
                if self.UsedGUIFlag;
                    Gui.UpdateLogBox(strcat("Starting..."," @ ",string(datetime('now','Format','HH:mm:ss'))));
                end
                
                if self.ShouldSaveFlag;
                    self.MakeDimensionMap();
                    if self.SaveToSameFileFlag();
                        self.SelfPrepareNetCDF();
                    end
                    if self.SaveToRunFilesFlag();
                        for Run_Index = 1:numel(Runs);
                            self.Runs(Run_Index).SelfPrepareNetCDF();
                        end
                    end
                end
                
%                 try
                % Loop for runs
                for Run_Index = 1:numel(self.Runs);           
                    % Start Save
                    if self.ShouldSaveFlag && self.SaveToRunFilesFlag;
                        self.Runs(Run_Index).Outputs.StartSave(self.OutputFile,self.GetDimensionSizes(),self.DimensionMap);
                    end
                    
                    % Keep a copy of initial
                    Initials_Copy = self.Runs(Run_Index).Regions(1).Conditions.Initials.Conditions;
                    
                    % Preallocate output arrays
                    DataChunks = cell(1:numel(self.Runs));
                    
                    % Loop for each chunk
                    for Chunk_Index = 1:numel(self.Runs(Run_Index).Chunks);
                        % Apply the relevant perturbations on a per model-run basis
                        self.Runs(Run_Index).Regions(1).Conditions.Perturb(self.Runs(Run_Index).Regions(1).Conditions.Perturbations.Matrix,Chunk_Index);
                        
                        % Create anonymous function
                        ODEFunc = eval(strcat("@(t,y,y_Sub,y_Meta,Chunk)",self.Runs(Run_Index).Regions(1).Conditions.Functionals.Core,"(t,y,y_Sub,y_Meta,Chunk,self.Runs(Run_Index).Regions(1))"));
                        
                        % Run the solver
                        SolverFunction = str2func(self.Runs(Run_Index).Regions(1).Conditions.Functionals.Solver);
                        DataChunks{Chunk_Index} = SolverFunction(ODEFunc,self.Runs(Run_Index),Chunk_Index);
                        
                        % Reset the initial conditions
                        if Run_Index~=numel(self.Runs);
                            self.Runs(Run_Index).Regions(1).Conditions.Initials.Conditions = DataChunks{Chunk_Index}{2}(:,end);
                            self.Runs(Run_Index).Regions(1).Conditions.Initials.Deal();
                        else
                            self.Runs(Run_Index).Regions(1).Conditions.Initials.Conditions = Initials_Copy;
                            self.Runs(Run_Index).Regions(1).Conditions.Initials.Deal();
                        end
                    end
                    
                    for Chunk_Index = 1:numel(DataChunks);
                        DataRun{Chunk_Index} = DataChunks{Chunk_Index}{1};
                        ParameterRun{Chunk_Index} = DataChunks{Chunk_Index}{2};
                        PICRun{Chunk_Index} = DataChunks{Chunk_Index}{3};
                    end
                    
                    % Assign to model object
                    self.UnpackData(Run_Index,1,horzcat(DataRun{:}));
                    self.Runs(Run_Index).Regions(1).Conditions.AssignConstants(horzcat(ParameterRun{:}));
                    self.Runs(Run_Index).Regions(1).Conditions.Presents.Carbon.PIC_Burial = horzcat(PICRun{:});
                    
                    if self.UsedGUIFlag;
                        % Display when run is complete
                        Gui.UpdateLogBox(strcat("Run number ",num2str(Run_Index)," of ",num2str(numel(self.Runs))," complete @ ",string(datetime('now','Format','HH:mm:ss'))));
                    end
                    
                    % Save data to one file when each run is done
                    if self.ShouldSaveFlag;
                        if self.SaveToSameFileFlag;
                            self.Runs(Run_Index).Save(self.Information.OutputFile);
                        end
                        if self.SaveToRunFilesFlag;
                            self.Runs(Run_Index).Save(self.Runs(Run_Index).Information.OutputFile);
                        end
                    end
                                        
                    % Email
%                     sendtheemail('ross.whiteford@soton.ac.uk','Model Run Complete',['Your model run saving to ',self.OutputFilepath,' finished at ',char(datetime('now','Format','HH:mm:ss'))])
                end
%                 catch ME
%                     self.UpdateLogBox('Error!');
%                 end
                  
                % Print to log box
                if self.UsedGUIFlag;
                    Gui.UpdateLogBox("Successfully completed");
                    Gui.ColourBox.BackgroundColor = [0,0.5,0.3];
                end

                profile off;
            end
        end
        
        %% Saving
        function DeleteExistingFile(self); 
            if self.ShouldSaveFlag && self.SaveToSameFileFlag;
                if self.CheckFileExists(self.Information.OutputFile);
                    delete(char(self.Information.OutputFile));
                end
            end
        end
        function SetOutputFile(self,Filename);
            self.Information.OutputFilename = Filename;
        end
        function ParseReplicationData(self,Replication);
            self.RunTable = Replication{1};
            self.PertTable = Replication{2};
            self.VarTable = Replication{3};
            self.InitTable = Replication{4};
        end
        function Replication_Data = MakeReplicationData(self);
            % Glue together run replication data, which is glued together
            % regional data
            Replication_Data = self.Runs(1).MakeReplicationData();
        end
        function ParseTransientData(self,Gui);
            if self.UsedGUIFlag;
                for Run_Index = 1:numel(Gui.TransMatrix);
                    for Region_Index = 1;
                        Temporary_Transient_Matrix = [];
                        for Transient_Index = 1:size(Gui.TransMatrix{Run_Index},1);
                            if ~isnan(str2double(Gui.TransMatrix{Run_Index}(Transient_Index,2)));
                                Chunk_Number = str2double(Gui.TransMatrix{Run_Index}(Transient_Index,2));
                            else
                                Chunk_Number = ':';
                            end
                            if ~isnan(str2double(Gui.TransMatrix{Run_Index}(Transient_Index,5)))
                                Depth_Number = str2double(Gui.TransMatrix{Run_Index}(Transient_Index,5));
                            else
                                Depth_Number = ':';
                            end
                            Function_Handle = str2func(['@(t,Conditions)',Gui.TransMatrix{Run_Index}{Transient_Index,6}]);
                            Temporary_Transient_Matrix = [Temporary_Transient_Matrix;{Chunk_Number,Gui.TransMatrix{Run_Index}{Transient_Index,3},Gui.TransMatrix{Run_Index}{Transient_Index,4},Depth_Number,Function_Handle}];
                        end
                        self.Runs(Run_Index).Regions(Region_Index).Conditions.Transients.Matrix = Temporary_Transient_Matrix;
                        self.Runs(Run_Index).Regions(Region_Index).Conditions.Transients.DealMatrix();
                    end
                end
            else
                for Run_Index = 1:numel(Gui.TransMatrix);
                    for Region_Index = 1;
                        self.Runs(Run_Index).Regions(Region_Index).Conditions.Transients.UndealTransientMatrix();
                    end
                end
            end
        end
        function ParsePerturbationData(self,Gui);
            if self.UsedGUIFlag;
                for Run_Index = 1:numel(Gui.PertMatrix);
                    for Region_Index = 1;
                        Temporary_Matrix = [];
                        if ~isempty(Gui.PertMatrix);
                            for Perturbation_Index = 1:size(Gui.PertMatrix{Run_Index},1);
                                if ~isnan(str2double(Gui.PertMatrix{Run_Index}(Perturbation_Index,2)));
                                    Chunk_Number = str2double(Gui.PertMatrix{Run_Index}(Perturbation_Index,2));
                                else
                                    Chunk_Number = ':';
                                end
                                if ~isnan(str2double(Gui.PertMatrix{Run_Index}(Perturbation_Index,5)))
                                    Depth_Number = str2double(Gui.PertMatrix{Run_Index}(Perturbation_Index,5));
                                else
                                    Depth_Number = ':';
                                end
                                Function_Handle = str2func(['@(Conditions)',Gui.PertMatrix{Run_Index}{Perturbation_Index,7}]);
                                Temporary_Matrix = [Temporary_Matrix;{Chunk_Number,Gui.PertMatrix{Run_Index}{Perturbation_Index,3},Gui.PertMatrix{Run_Index}{Perturbation_Index,4},Gui.PertMatrix{Run_Index}{Perturbation_Index,5},Depth_Number,Function_Handle}];
                            end
                            self.Runs(Run_Index).Regions(Region_Index).Conditions.Perturbations.Matrix = Temporary_Matrix;
                            self.Runs(Run_Index).Regions(Region_Index).Conditions.Perturbations.DealMatrix();
                        end
                    end
                end
            else
                for Run_Index = 1:numel(Gui.TransMatrix);
                    for Region_Index = 1;
                        self.Runs(Run_Index).Regions(Region_Index).Conditions.Transients.UndealTransientMatrix();
                    end
                end
            end
        end
        function SelfPrepareNetCDF(self);
            File = self.Information.OutputFile;
            Parameter_Group_Names = self.Runs(1).Regions(1).Conditions.GetShallowNames(self.Runs(1).Regions(1).Conditions.Constants);
            Parameter_Names = self.Runs(1).Regions(1).Conditions.GetDeepNames(self.Runs(1).Regions(1).Conditions.Constants);
            Maximum_Data_Sizes = self.GetMaximumDimensionSizes();
            Dimension_Map = self.Runs(1).Regions(1).Conditions.Presents.DimensionMap;
            Data_Names = properties(self.Runs(1).Regions(1).Outputs);
            Data_Size_Map = self.Runs(1).Regions(1).Outputs.Data_Size_Map;
            Replication_Data = self.MakeReplicationData();
            Model = self.Information.Model_Name;
            Core = char(self.Runs(1).Regions(1).Conditions.Functionals.Core);
            Solver = char(self.Runs(1).Regions(1).Conditions.Functionals.Solver);
            CoreSolver = {Core,Solver};
            for Run_Index = 1:numel(self.Runs);
                Transient_Matrices{Run_Index} = self.Runs(Run_Index).Regions(1).Conditions.Transients.Matrix;
            end
            for Run_Index = 1:numel(self.Runs);
                Perturbation_Matrices{Run_Index} = self.Runs(Run_Index).Regions(1).Conditions.Perturbations.Matrix;
            end
            
            GECCO.PrepareNetCDF(File,Model,Data_Names,Maximum_Data_Sizes,Data_Size_Map,Parameter_Group_Names,Parameter_Names,Dimension_Map,Transient_Matrices,Perturbation_Matrices,Replication_Data,CoreSolver);
        end
        
        %%
        function UnpackData(self,Run_Index,Region_Index,Data);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Time = Data(1,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Atmosphere_CO2 = Data(2,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Algae = Data(3,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Phosphate = Data(4:5,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.DIC = Data(6:7,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Alkalinity = Data(8:9,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Atmosphere_Temperature = Data(10,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Ocean_Temperature = Data(11:12,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Silicate = Data(13,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Carbonate = Data(14,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Silicate_Weathering_Fraction = Data(15,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Carbonate_Weathering_Fraction = Data(16,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Radiation = Data(17,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Ice = Data(18,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Sea_Level = Data(19,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Snow_Line = Data(20,:);
            
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Lysocline = Data(21,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Seafloor_Total = Data(22,:);
            if size(Data,1)>22;
                self.Runs(Run_Index).Regions(Region_Index).Outputs.Cores = Data(23:end,:);
            end
        end
        %%
        function [Transients_Number,Transient_Sizes] = GetTransientSizes(self);
            Count = 0;
            for Run_Index = 1:numel(self.Runs);
                for Region_Index = 1:numel(self.Runs(Run_Index).Regions);
                    Temporary_Transient_Sizes = [];
                    Current_Transient_Chars = GECCO.CharacterifyCells(self.Runs(Run_Index).Regions(Region_Index).Conditions.Transients.Matrix);
                    for Transient_Index = 1:size(self.Runs(Run_Index).Regions(Region_Index).Conditions.Transients.Matrix,1);               
                        Char_Array{Transient_Index} = join(Current_Transient_Chars(Transient_Index,:),',');
                        Temporary_Transient_Sizes(Transient_Index) = size(Char_Array{Transient_Index}{1},2);
                        Count = Count+1;
                    end
                    if isempty(Temporary_Transient_Sizes);
                        Transient_Sizes(Region_Index,Run_Index) = 0;
                    else
                        Transient_Sizes(Region_Index,Run_Index) = max(Temporary_Transient_Sizes);
                    end
                end
            end
            Transients_Number = Count;
        end
        function [Perturbations_Number,Perturbation_Sizes] = GetPerturbationSizes(self);
            Count = 0;
            for Run_Index = 1:numel(self.Runs);
                for Region_Index = 1:numel(self.Runs(Run_Index).Regions);
                    Temporary_Sizes = [];
                    Current_Perturbation_Chars = GECCO.CharacterifyCells(self.Runs(Run_Index).Regions(Region_Index).Conditions.Perturbations.Matrix);
                    for Transient_Index = 1:size(self.Runs(Run_Index).Regions(Region_Index).Conditions.Perturbations.Matrix,1);               
                        Char_Array{Transient_Index} = join(Current_Perturbation_Chars(Transient_Index,:),',');
                        Temporary_Sizes(Transient_Index) = size(Char_Array{Transient_Index}{1},2);
                        Count = Count+1;
                    end
                    if isempty(Temporary_Sizes);
                        Perturbation_Sizes(Region_Index,Run_Index) = 0;
                    else
                        Perturbation_Sizes(Region_Index,Run_Index) = max(Temporary_Sizes);
                    end
                end
            end
            Perturbations_Number = Count;
        end
        
        %% Loading Data
        function LoadDataIntoModel(self,src,event);
            self.InstantiateModel;
            self.Model.Data = self.LoadData(self.FileInputUI.String);
            self.Model.Time = self.LoadTime(self.FileInputUI.String);
            self.Model.Lysocline = self.LoadLysocline(self.FileInputUI.String);
            self.Model.Seafloor = self.LoadSeafloor(self.FileInputUI.String);
            self.Model.Seafloor_Total = self.LoadSeafloorTotal(self.FileInputUI.String);
            try
                self.Model.Outgassing = self.LoadOutgassing(self.FileInputUI.String);
            catch
                self.Model.Outgassing = self.LoadMetamorphism(self.FileInputUI.String);
            end
            self.Model.Conditions.Present.PIC_Burial = self.LoadPICBurial(self.FileInputUI.String);
            self.Model.Conditions.Present.Carbonate_Surface_Sediment_Lock = self.LoadLock(self.FileInputUI.String);
            self.Model.Cores = self.LoadCores(self.FileInputUI.String);
            self.LoadConstsCallback;
            self.PlotRunSelectorUI.String = strsplit(num2str(1:size(self.Model.Time,3)),' ');
        end
        function LoadFinal(self,src,event);
            if isempty(self.FileInputUI.String);
                self.UpdateLogBox("Please select an input file");
            elseif isempty(self.Model);
                self.UpdateLogBox("Please instantiate the model first");
            else
                Data = self.LoadData(self.FileInputUI.String);
                if numel(self.Runs)==size(Data,3);
                    for RunNumber = 1:numel(self.Runs);
                        self.Model.Conditions(RunNumber).Initial.Conditions = Data(:,end,RunNumber);
                        Lysocline = self.LoadLysocline(self.FileInputUI.String);
                        self.Model.Conditions(RunNumber).Present.Lysocline = Lysocline(end);            
                    end
                elseif numel(self.Runs)>size(Data,3);
                    for RunNumber = 1:numel(self.Runs);
                        self.Model.Conditions.Initial(RunNumber).Conditions = Data(end,:,1);
                    end
                    self.UpdateLogBox("More runs than initial conditions, used output from run 1");
                elseif numel(self.Runs)<size(Data,3);
                    for RunNumber = 1:numel(self.Runs);
                        self.Model.Conditions.Initial(RunNumber).Conditions = Data(end,:,RunNumber);
                    end
                    self.UpdateLogBox("More initial conditions than runs");
                end
                self.Model.Conditions.Deal();
            end
        end
        function LoadPerturbations(self,Filename);
            self.Runs(1).Regions(1).Conditions.Perturbations.Load(Filename);
            self.Runs(1).Regions(1).Conditions.Perturbations.UndealMatrix();
        end
        function LoadTransients(self,Filename);
            self.Runs(1).Regions(1).Conditions.Transients.Load(Filename);
            self.Runs(1).Regions(1).Conditions.Transients.UndealMatrix();
        end
        %% Reset
        function Reset(self,src,event);
            self.Model.Outgassing = []; %cat(3,self.Model.Conditions.Initial.Outgassing);
            self.Model.Seafloor =  []; %cat(3,self.Model.Conditions.Initial.Subduction);
            
            for Run_Index = 1:numel(self.Runs);
                if ~isempty(self.Model.Conditions(Run_Index).Initial.Outgassing);
                    MaxOutgas = self.Model.GetMaxOutgassing(self.Runs);
                    self.Model.Conditions(Run_Index).Initial.Outgassing = []; %zeros(MaxMeta(Run_Index),1);
                end
            end
        end
end
end