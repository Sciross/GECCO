classdef GECCO < handle
    properties
        Runs@Run
        Information@Information
    end
    properties (Hidden=true)
        Validated_Flag = 0;
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
        SaveToRegionFilesFlag = 0;
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
            Dims = {'s',Values(5)};
            netcdf.defDim(FileID,Dims{1},Dims{2});
            
            % Carbonate
            Dimc = {'c',Values(6)};
            netcdf.defDim(FileID,Dimc{1},Dimc{2});
            
            % Outgassing
            Dimm = {'m',Values(7)};
            netcdf.defDim(FileID,Dimm{1},Dimm{2});
            
            % Gauss
            Dimg = {'g',Values(8)};
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
                        CurrentDims{2} = 't';
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
            Dimk_3 = {'k_3',3};
            Dimk_6 = {'k_6',6};
            Dimk_13 = {'k_13',13};
            
            netcdf.defDim(FileID,Dimk_3{1},Dimk_3{2});
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
            Run_Stuff = Replication_Data{1}{1};
            Initial_Stuff = Replication_Data{1}{2};
            
            for Run_Index = 1:numel(Replication_Data);
                Run_Stuff_Sizes(Run_Index) = size(Replication_Data{Run_Index}{1},1);
            end
            
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            Dim_r1 = {'c_1',max(Run_Stuff_Sizes)};
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
            netcdf.defVar(RepGrpID,'Run_Matrix','double',GECCO.DimToDimID(FileID,CurrentDims));
            
            CurrentDims = {'i_2','t_0','r','R'};
            netcdf.defVar(RepGrpID,'Initial_Matrix','double',GECCO.DimToDimID(FileID,CurrentDims));
            
            CurrentDims = {'s','t_0','r','R'};
            netcdf.defVar(RepGrpID,'Initial_Seafloor','double',GECCO.DimToDimID(FileID,CurrentDims));
  
            CurrentDims = {'m','t_0','r','R'};
            netcdf.defVar(RepGrpID,'Initial_Outgassing','double',GECCO.DimToDimID(FileID,CurrentDims));

            netcdf.endDef(FileID);
            netcdf.close(FileID);
        end
        function AddReplicatoryData(Filename,Replication_Data);
            FileID = netcdf.open(Filename,'WRITE');
            RepGrpID = netcdf.inqNcid(FileID,'Replication');
            

            Run_MatrixID = netcdf.inqVarID(RepGrpID,'Run_Matrix');
            for Run_Index = 1:numel(Replication_Data);            
                % Specify start and stride
                Region_Index = 1;
                Start = [0,0,Region_Index-1,Run_Index-1];
                Count = [size(Replication_Data{Run_Index}{1},1),size(Replication_Data{Run_Index}{1},2),1,1];
                Stride = [1,1,1,1];
                
                netcdf.putVar(RepGrpID,Run_MatrixID,Start,Count,Stride,Replication_Data{Run_Index}{1});
            
                Start = [0,0,Region_Index-1,Run_Index-1];
                Count = [numel(Replication_Data{Run_Index}{2}),1,1,1];
                Stride = [1,1,1,1];
                Init_MatrixID = netcdf.inqVarID(RepGrpID,'Initial_Matrix');
                netcdf.putVar(RepGrpID,Init_MatrixID,Start,Count,Stride,Replication_Data{Run_Index}{2});
                
                Start = [0,0,Region_Index-1,Run_Index-1];
                Count = [numel(Replication_Data{Run_Index}{3}),1,1,1];
                Stride = [1,1,1,1];
                Init_SeafloorID = netcdf.inqVarID(RepGrpID,'Initial_Seafloor');
                Initial_Seafloor = Replication_Data{Run_Index}{3};
                netcdf.putVar(RepGrpID,Init_SeafloorID,Start,Count,Stride,Initial_Seafloor);
                
                Start = [0,0,Region_Index-1,Run_Index-1];
                Count = [numel(Replication_Data{Run_Index}{4}),1,1,1];
                Stride = [1,1,1,1];
                Init_OutgassingID = netcdf.inqVarID(RepGrpID,'Initial_Outgassing');
                Initial_Outgassing = Replication_Data{Run_Index}{4};
                netcdf.putVar(RepGrpID,Init_OutgassingID,Start,Count,Stride,Initial_Outgassing);
            end
            
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
                Transients_Done = string();
                for Transient_Index = 1:size(Transient_Matrices{Run_Index},1);
                    if ~any(strcmp(strcat(Transient_Matrices{Run_Index}{Transient_Index,2},Transient_Matrices{Run_Index}{Transient_Index,3}),Transients_Done));
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
                        
                        
                        Transients_Done = [Transients_Done;strcat(Transient_Matrices{Run_Index}{Transient_Index,2},Transient_Matrices{Run_Index}{Transient_Index,3})];
                    end
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
            % First define the variable  
            CurrentDims = {'k','u_2','r','R'};
            netcdf.reDef(FileID);
            CoreVarID = netcdf.defVar(FuncGrpID,'Core','char',GECCO.DimToDimID(FileID,CurrentDims));
            SolverVarID = netcdf.defVar(FuncGrpID,'Solver','char',GECCO.DimToDimID(FileID,CurrentDims));
            netcdf.endDef(FileID);
                    
            for Run_Index = 1:Run_Number;  
                Start = [0,0,0,Run_Index-1];
                Count = [1,numel(char(CoreSolver{1}{Run_Index}{1})),1,1];
                netcdf.putVar(FuncGrpID,CoreVarID,Start,Count,char(CoreSolver{1}{Run_Index}{1}));
                
                Count = [1,numel(char(CoreSolver{2}{Run_Index}{1})),1,1];
                netcdf.putVar(FuncGrpID,SolverVarID,Start,Count,char(CoreSolver{2}{Run_Index}{1}));
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
            Values(3) = self.GetMaximumChunkNumber();
            Values(4) = self.GetMaximumSizeOf("Initials","Conditions");
            Values(5) = self.GetMaximumSizeOf("Constants","Architecture","Hypsometric_Bin_Midpoints");
            Values(6) = self.GetMaximumSizeOf("Constants","Seafloor","Core_Depths"); %max(self.GetCoreDepthSize());
            Values(7) = self.GetMaximumSizeOf("Initials","Outgassing"); %max(self.GetOutgassingSize());
            Values(8) = self.GetMaximumSizeOf("Presents","Outgassing","Gauss"); %max(self.GetOutgassingGaussianSize());        
        end
        function MakeDimensionMap(self,Run_Number);
            if nargin<2;
                for Run_Index = 1:numel(self.Runs);
                    self.Runs(Run_Index).Regions(1).Conditions.Presents.MakeDimensionMap();
                    self.Runs(Run_Index).Regions(1).Conditions.Presents.UpdateDimensionMap(self.Runs(Run_Index).Regions(1).Conditions.Transients.Matrix);
                end
            else
                for Run_Index = Run_Number;
                    self.Runs(Run_Index).Regions(1).Conditions.Presents.MakeDimensionMap();
                    self.Runs(Run_Index).Regions(1).Conditions.Presents.UpdateDimensionMap(self.Runs(Run_Index).Regions(1).Conditions.Transients.Matrix);
                end
            end
        end
        
        function Maximum_Chunk_Number = GetMaximumChunkNumber(self);
            for Run_Index = 1:numel(self.Runs);
                Chunk_Number(Run_Index) = numel(self.Runs(Run_Index).Chunks);
            end
            Maximum_Chunk_Number = max(Chunk_Number);
        end
        function Sizes = GetSizeOf(self,Type,Group,Name);
            if nargin<4;
                Name = Group;
                Group = "";
            end
            Sizes = self.Runs.GetSizeOf(Type,Group,Name);
        end
        function GetCellMaximum(self,Cell);
            Value = [];
            for Cell_Index = 1:numel(Cell);
                if isempty(Value) || Cell{Cell_Index}>Value;
                    Value = Cell{Cell_Index};
                end
            end
        end
        function Cell = CellMaximumIterate(self,Cell);
            while iscell(Cell);
                for Cell_Index = 1:numel(Cell);
                    if ~iscell(Cell);
                        break
                    elseif iscell(Cell{Cell_Index});
                        Cell{Cell_Index} = self.CellMaximumIterate(Cell{Cell_Index});
                    else
                        Cell = max(Cell{Cell_Index});
                    end
                end
            end
            
        end
        function Maximum_Size = GetMaximumSizeOf(self,Type,Group,Name);
            if nargin<4;
                Name = Group;
                Group = "";
            end
            
            Sizes = self.GetSizeOf(Type,Group,Name);
            Maximum_Size = self.CellMaximumIterate(Sizes);
        end
        
        function Timestep = GetOutputTimestepCount(self);
            for Run_Index = 1:numel(self.Runs);
                Timestep(Run_Index) = self.Runs(Run_Index).GetOutputTimestepCount();
            end
        end
        
        function Validate(self,Gui);
            self.Validated_Flag = 1;
            
            self.ValidateGECCO();
            self.ValidateSaveFlags();
            self.Runs.Validate();
            
            if self.SaveToRunFilesFlag;
                self.Runs.ValidateSaveFlags();
            end
        end
        function ValidateGECCO(self);
            Max_Outgassing_Tracked = self.Runs(1).Regions(1).Conditions.GetMaxOutgassing(self.Runs(end).Chunks(end).Time_In(2));
            Initial_Outgassing_Length = self.Runs(1).Regions(1).Conditions.GetSizeOf("Initials","Outgassing");

            if numel(self.Runs)==0;
                self.Validated_Flag = 0;
                if self.UsedGUIFlag;
                    Gui.UpdateLogBox("No run details provided");
                end
            elseif sum(Max_Outgassing_Tracked<=Initial_Outgassing_Length | Initial_Outgassing_Length==0 | Initial_Outgassing_Length==1 | Initial_Outgassing_Length==2)==0;
                self.Validated_Flag = 0;
                if self.UsedGUIFlag;
                    Gui.UpdateLogBox(strcat("Initial Outgassing array is the wrong length, should be...",num2str(Max_Outgassing_Tracked)," elements"));
                end
            end            
        end
        function ValidateSaveFlags(self,Gui)
            if self.ShouldSaveFlag;
                if self.SaveToSameFileFlag; 
                % Whole file
                    if strcmp(self.Information.Output_File,"");
                        self.Validated_Flag = 0;
                    end
                end
            end
        end
        
        %% Run
        function RunModel(self,Runs_To_Do,Gui);
            if nargin<2;
                Runs_To_Do = 1:numel(self.Runs);
            end
            
            self.Information.SortOutFilepath();
            for Run_Index = 1:numel(Runs_To_Do);
                self.Runs(Runs_To_Do(Run_Index)).Information.SortOutFilepath();
                for Region_Index = 1:numel(self.Runs(Runs_To_Do(Run_Index)).Regions);
                    self.Runs(Runs_To_Do(Run_Index)).Regions(Region_Index).Information.SortOutFilepath();
                end
            end
            
            for Run_Index = 1:numel(Runs_To_Do);
                for Region_Index = 1:numel(self.Runs(Runs_To_Do(Run_Index)).Regions);
                    if size(self.Runs(Runs_To_Do(Run_Index)).Regions(Region_Index).Conditions.Constants.Carbon.PIC_Pelagic_Burial,2)>1;
                        self.Runs(Runs_To_Do(Run_Index)).Regions(Region_Index).Conditions.Constants.Carbon.PIC_Pelagic_Burial = self.Runs(Runs_To_Do(Run_Index)).Regions(Region_Index).Conditions.Constants.Carbon.PIC_Pelagic_Burial(:,end);
                    end
                end
            end
            
            if self.UsedGUIFlag;
                self.Validate(Gui);
            else
                self.Validate();
            end
            
            if self.Validated_Flag;
                if self.UsedGUIFlag;
                    self.ParseTransientData(Gui);
                else
                    self.ParseTransientData();
                end
                profile on;
                if self.UsedGUIFlag;
                    Gui.ColourBox.BackgroundColor = [1,1,0.5];
                    Gui.UpdateLogBox("Starting model runs...");
                    drawnow();
                end
                
                self.DeleteExistingFile();
                for Run_Index = 1:numel(Runs_To_Do);
                    self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Constants.Carbonate_Chemistry.SolverToHandle();
                    self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Constants.Carbonate_Chemistry.LysoclineSolverToHandle();
                    self.Runs(Runs_To_Do(Run_Index)).Regions(1).Outputs = Output();
                    self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.UpdatePresent();
                    self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.CalculateDependents(self.Runs(end).Chunks(end).Time_In(2));
                    self.Runs(Runs_To_Do(Run_Index)).Regions(1).Information = self.Runs(Runs_To_Do(Run_Index)).Information();
                    if self.SaveToRegionFilesFlag;
                        self.Runs(Runs_To_Do(Run_Index)).Regions(1).Information.Output_File = strcat(self.Runs(Runs_To_Do(Run_Index)).Regions(1).Information.Output_File,"_Region_",numstr(1));
                    end
                end
                
                if self.ShouldSaveFlag;
                    for Run_Index = 1:numel(Runs_To_Do);
                        self.MakeDimensionMap(Runs_To_Do(Run_Index));
                    end
                    
                    if self.SaveToSameFileFlag;
                        self.SelfPrepareNetCDF();
                    end
                    if self.SaveToRunFilesFlag;
                        for Run_Index = 1:numel(Runs_To_Do);
                            self.Runs(Runs_To_Do(Run_Index)).SelfPrepareNetCDF();
                        end
                    end
                    if self.SaveToRegionFilesFlag();
                        for Run_Index = 1:numel(Runs_To_Do);
                            for Region_Index = 1:numel(self.Runs(Runs_To_Do(Run_Index)).Regions);
                                self.Runs(Runs_To_Do(Run_Index)).Regions(Region_Index).SelfPrepareNetCDF();
                            end
                        end
                    end
                end
                
                try
                    % Loop for runs
                    for Run_Index = 1:numel(Runs_To_Do);
                        DateTime(1) = datetime('now');
                        if self.UsedGUIFlag;
                            Gui.UpdateLogBox(strcat("Run number ",num2str(Runs_To_Do(Run_Index))," of ",num2str(numel(Runs_To_Do))," starting "," @ ",string(datetime('now','Format','HH:mm:ss'))),1:numel(Runs_To_Do));
                        end
                        
                        % Keep a copy of initial
                        self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Initials.Undeal();
                        Initials_Copy = self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Initials.Conditions;
                        Initials_Seafloor_Copy = self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Initials.Seafloor;
                        Initials_Outgassing_Copy = self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Initials.Outgassing;

                        % Preallocate output arrays
                        DataChunks = cell(1:numel(self.Runs(Runs_To_Do(Run_Index)).Chunks));
                        for Chunk_Index = 1:numel(self.Runs(Runs_To_Do(Run_Index)).Chunks);
                            DataChunks{Chunk_Index} = cell(1,4);
                        end
                        DataRun = cell(0);
                        DependentRun = cell(0);
                        ParameterRun = cell(0);
                        PICRun = cell(0);
                        
                        % Loop for each chunk
                        for Chunk_Index = 1:numel(self.Runs(Runs_To_Do(Run_Index)).Chunks);
                            % Apply the relevant perturbations on a per model-run basis
                            self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Perturb(self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Perturbations.Matrix,Chunk_Index);
                            
                            % Create anonymous function
                            ODEFunc = eval(strcat("@(t,y,y_Sub,y_Meta,Chunk)",self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Functionals.Core,"(t,y,y_Sub,y_Meta,Chunk,self.Runs(Runs_To_Do(Run_Index)).Regions(1))"));
                            
                            % Run the solver
                            SolverFunction = str2func(self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Functionals.Solver);
                            [DataChunks{Chunk_Index},Chunk_Flag] = SolverFunction(ODEFunc,self.Runs(Runs_To_Do(Run_Index)),Chunk_Index);
                            
                            % Reset the initial conditions
                            if Chunk_Index~=numel(self.Runs(Runs_To_Do(Run_Index)).Chunks) & Chunk_Flag;
                                self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Initials.Conditions = DataChunks{Chunk_Index}{1}(:,end);
                                self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Initials.Deal();
                                self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Initials.Seafloor = self.Runs(Runs_To_Do(Run_Index)).Regions.Outputs.Seafloor;
                                self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Initials.Outgassing = self.Runs(Runs_To_Do(Run_Index)).Regions.Outputs.Outgassing;
                            else
                                self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Initials.Conditions = Initials_Copy;
                                self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Initials.Deal();
                                self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Initials.Seafloor = Initials_Seafloor_Copy;
                                self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Initials.Outgassing = Initials_Outgassing_Copy;
                            end
                            
                            if ~Chunk_Flag;
                                break
                            end
                        end
                        
                        for Chunk_Index = 1:numel(DataChunks);
                            DataRun{Chunk_Index} = DataChunks{Chunk_Index}{1};
                            DependentRun{Chunk_Index} = DataChunks{Chunk_Index}{2};
                            ParameterRun{Chunk_Index} = DataChunks{Chunk_Index}{3};
                            PICRun{Chunk_Index} = DataChunks{Chunk_Index}{4};
                        end
                        
                        % Assign to model object
                        self.UnpackData(Runs_To_Do(Run_Index),1,horzcat(DataRun{:}),horzcat(DependentRun{:}));
                        self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.AssignConstants(horzcat(ParameterRun{:}));
                        self.Runs(Runs_To_Do(Run_Index)).Regions(1).Conditions.Presents.Carbon.PIC_Pelagic_Burial = horzcat(PICRun{:});
                        
                        if self.UsedGUIFlag;
                            % Display when run is complete
                            Gui.UpdateLogBox(strcat("Run number ",num2str(Runs_To_Do(Run_Index))," of ",num2str(numel(Runs_To_Do))," complete @ ",string(datetime('now','Format','HH:mm:ss'))),1:numel(Runs_To_Do));
                        end
                        
                        % Save data to one file when each run is done
                        if self.ShouldSaveFlag;
                            if self.SaveToSameFileFlag;
                                self.Runs(Runs_To_Do(Run_Index)).Regions(1).Save(self.Information,1,Runs_To_Do(Run_Index));
                            end
                            if self.SaveToRunFilesFlag;
                                self.Runs(Runs_To_Do(Run_Index)).Regions(1).Save(self.Runs(Runs_To_Do(Run_Index)).Information,1,1);
                            end
                            if self.SaveToRegionFilesFlag;
                                for Region_Index = 1:numel(self.Runs(Runs_To_Do(Run_Index)).Regions);
                                    self.Runs(Runs_To_Do(Run_Index)).Regions(Region_Index).Save(self.Runs(Runs_To_Do(Run_Index)).Regions(Region_Index).Information,Region_Index,Runs_To_Do(Run_Index));
                                end
                            end
                        end
                        
                        % Email
                        if ispc;
                            sendtheemail('ross.whiteford@soton.ac.uk','Model Run Complete',['Your model run finished at ',char(datetime('now','Format','HH:mm:ss'))])
                        end
                    end
                catch ME
                    if self.UsedGUIFlag;
                        Gui.UpdateLogBox('Error!');
                    else
                        disp('Error!');
                    end                    
                    profile off
                    error("Something went wrong, try-catch triggered");
                end
                  
                % Print to log box
                if self.UsedGUIFlag;
                    Gui.UpdateLogBox("Successfully completed model runs!");
                    Gui.ColourBox.BackgroundColor = [0,0.5,0.3];
                end

                profile off;
            end
        end
        function self = RunModelSingleRun(self,Run_Index,Gui);
            self.Information.SortOutFilepath();
            self.Runs(Run_Index).Information.SortOutFilepath();
            for Region_Index = 1:numel(self.Runs(Run_Index).Regions);
                self.Runs(Run_Index).Regions(Region_Index).Information.SortOutFilepath();
            end
            
            for Region_Index = 1:numel(self.Runs(Run_Index).Regions);
                if size(self.Runs(Run_Index).Regions(Region_Index).Conditions.Constants.Carbon.PIC_Pelagic_Burial,2)>1;
                    self.Runs(Run_Index).Regions(Region_Index).Conditions.Constants.Carbon.PIC_Pelagic_Burial = self.Runs(Run_Index).Regions(Region_Index).Conditions.Constants.Carbon.PIC_Pelagic_Burial(:,end);
                end
            end
            
            if self.UsedGUIFlag;
                self.Validate(Gui);
            else
                self.Validate();
            end
            
            if self.Validated_Flag && self.Runs(Run_Index).Validated_Flag;
                if self.UsedGUIFlag;
                    Gui.ColourBox.BackgroundColor = [1,1,0.5];
                    Gui.UpdateLogBox("Starting model runs...");
                    drawnow();
                end
                
                self.DeleteExistingFile();
                self.Runs(Run_Index).Regions(1).Conditions.Constants.Carbonate_Chemistry.SolverToHandle();
                self.Runs(Run_Index).Regions(1).Conditions.Constants.Carbonate_Chemistry.LysoclineSolverToHandle();
                self.Runs(Run_Index).Regions(1).Outputs = Output();
                self.Runs(Run_Index).Regions(1).Conditions.UpdatePresent();
                self.Runs(Run_Index).Regions(1).Conditions.CalculateDependents(self.Runs(end).Chunks(end).Time_In(2));
                self.Runs(Run_Index).Regions(1).Information = self.Runs(Run_Index).Information();
                if self.SaveToRegionFilesFlag;
                    self.Runs(Run_Index).Regions(1).Information.Output_File = strcat(self.Runs(Run_Index).Regions(1).Information.Output_File,"_Region_",numstr(1));
                end
                    
                if self.ShouldSaveFlag;
                    self.MakeDimensionMap(Run_Index);
                    if self.SaveToSameFileFlag();
                        self.SelfPrepareNetCDF();
                    end
                    if self.SaveToRunFilesFlag();
                        self.Runs(Run_Index).SelfPrepareNetCDF();
                    end
                    if self.SaveToRegionFilesFlag();
                        for Region_Index = 1:numel(self.Runs(Run_Index).Regions);
                                self.Runs(Run_Index).Regions(Region_Index).SelfPrepareNetCDF();
                            end
                    end
                end
                
%                 try
                % Loop for runs
                DateTime(1) = datetime('now');
                if self.UsedGUIFlag;
                    Gui.UpdateLogBox(strcat("Run number ",num2str(Run_Index)," of ",num2str(numel(self.Runs))," starting "," @ ",string(datetime('now','Format','HH:mm:ss'))),1:numel(self.Runs));
                end
                    
                % Keep a copy of initial
                Initials_Copy = self.Runs(Run_Index).Regions(1).Conditions.Initials.Conditions;
                  
                % Preallocate output arrays
                DataChunks = cell(1:numel(self.Runs(Run_Index).Chunks));
                  
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
                        self.Runs(Run_Index).Regions(1).Conditions.Initials.Conditions = DataChunks{Chunk_Index}{1}(:,end);
                        self.Runs(Run_Index).Regions(1).Conditions.Initials.Deal();
                    else
                        self.Runs(Run_Index).Regions(1).Conditions.Initials.Conditions = Initials_Copy;
                        self.Runs(Run_Index).Regions(1).Conditions.Initials.Deal();
                    end
                end
                    
                for Chunk_Index = 1:numel(DataChunks);
                    DataRun{Chunk_Index} = DataChunks{Chunk_Index}{1};
                    DependentRun{Chunk_Index} = DataChunks{Chunk_Index}{2};
                    ParameterRun{Chunk_Index} = DataChunks{Chunk_Index}{3};
                    PICRun{Chunk_Index} = DataChunks{Chunk_Index}{4};
                end
                    
                % Assign to model object
                self.UnpackData(Run_Index,1,horzcat(DataRun{:}),horzcat(DependentRun{:}));
                self.Runs(Run_Index).Regions(1).Conditions.AssignConstants(horzcat(ParameterRun{:}));
                self.Runs(Run_Index).Regions(1).Conditions.Presents.Carbon.PIC_Pelagic_Burial = horzcat(PICRun{:});
                    
                if self.UsedGUIFlag;
                    % Display when run is complete
                    Gui.UpdateLogBox(strcat("Run number ",num2str(Run_Index)," of ",num2str(numel(self.Runs))," complete @ ",string(datetime('now','Format','HH:mm:ss'))),1:numel(self.Runs));
                end
                    
                % Save data to one file when each run is done
                if self.ShouldSaveFlag;
                    if self.SaveToSameFileFlag;
                        self.Runs(Run_Index).Regions(1).Save(self.Information,1,Run_Index);
                    end
                    if self.SaveToRunFilesFlag;
                        self.Runs(Run_Index).Regions(1).Save(self.Runs(Run_Index).Information,1,1);
                    end
                    if self.SaveToRegionFilesFlag;
                        for Region_Index = 1:numel(self.Runs(Run_Index).Regions);
                            self.Runs(Run_Index).Regions(Region_Index).Save(self.Runs(Run_Index).Regions(Region_Index).Information,Region_Index,Run_Index);
                        end
                    end
                end
                    
                % Print to log box
                if self.UsedGUIFlag;
                    Gui.UpdateLogBox("Successfully completed model runs!");
                    Gui.ColourBox.BackgroundColor = [0,0.5,0.3];
                end
            end
        end
        function [Job,Task] = RunModelOnIridis(self,Cluster);
            if nargin<2;
            % Create a cluster object
                Cluster = parcluster;
            end
            % Create a job
            Job = createJob(Cluster);
            Additional_Paths = strsplit(genpath('~/Queen_Model/'),':');
            Job.AdditionalPaths = Additional_Paths(~cellfun('isempty',Additional_Paths));
            
            % Manipulate self here
            
            % Create tasks
            for Run_Index = 1:numel(self.Runs);
                Task{Run_Index} = createTask(Job,@self.RunModel,0,{Run_Index});
            end
            
            submit(Job);
            
        end
        
        %% Merging
        function Unmerged_Names = GetUnmergedParameterGroupNames(self);
            Unmerged_Names = self.Runs.GetUnmergedParameterGroupNames();
        end
        function Merged_Names = MergeParameterGroupNames(self,Unmerged_Names);
            Names = "";
            for Run_Index = 1:numel(Unmerged_Names);
                for Region_Index = 1:numel(Unmerged_Names{Run_Index});
                    Names = [Names;Unmerged_Names{Run_Index}{Region_Index}];
                end
            end
            Merged_Names = unique(Names,'stable');
            Merged_Names = Merged_Names(~strcmp(Merged_Names,""));
        end
        function Merged_Names = GetMergedParameterGroupNames(self);
            Unmerged_Names = self.GetUnmergedParameterGroupNames();
            Merged_Names = self.MergeParameterGroupNames(Unmerged_Names);
        end
        
        function Unmerged_Names = GetUnmergedParameterNames(self);
            Unmerged_Names = self.Runs.GetUnmergedParameterNames();
        end
        function Merged_Names = MergeParameterNames(self,Unmerged_Names);
            % Get maximum size
            for Run_Index = 1:numel(Unmerged_Names);
                for Region_Index = 1:numel(Unmerged_Names{Run_Index});
                    Sizes(Region_Index,Run_Index) = numel(Unmerged_Names{Run_Index}{Region_Index});
                end
            end
            Maximum_Group_Number = max(Sizes(:));
            
            Names = cell(1,Maximum_Group_Number);
            for Run_Index = 1:numel(Unmerged_Names);
                for Region_Index = 1:numel(Unmerged_Names{Run_Index});
                    for Group_Index = 1:numel(Unmerged_Names{Run_Index}{Region_Index});
                        if isempty(Names{Group_Index});
                            Names{Group_Index} = "";
                        end
                        Names{Group_Index} = [Names{Group_Index};Unmerged_Names{Run_Index}{Region_Index}{Group_Index}];
                    end
                end
            end
            
            for Group_Index = 1:numel(Names);
                Merged_Names{Group_Index} = unique(Names{Group_Index});
                Merged_Names{Group_Index} = Merged_Names{Group_Index}(~strcmp(Merged_Names{Group_Index},""));
            end
        end
        function Merged_Names = GetMergedParameterNames(self);
            Unmerged_Names = self.GetUnmergedParameterNames();
            Merged_Names = self.MergeParameterNames(Unmerged_Names);
        end
        
        function Unmerged_Names = GetUnmergedDataNames(self);
            Unmerged_Names = self.Runs.GetUnmergedDataNames();
        end
        function Merged_Names = MergeDataNames(self,Unmerged_Names);
            Names = "";
            for Run_Index = 1:numel(Unmerged_Names);
                for Region_Index = 1:numel(Unmerged_Names{Run_Index});
                    Names = [Names;Unmerged_Names{Run_Index}{Region_Index}];
                end
            end
            Merged_Names = unique(Names);
            Merged_Names = Merged_Names(~strcmp(Merged_Names,""));
        end
        function Merged_Names = GetMergedDataNames(self);
            Unmerged_Names = self.GetUnmergedDataNames();
            Merged_Names = self.MergeDataNames(Unmerged_Names);
        end
        
        function Unmerged_Sizes = GetUnmergedDataSizes(self);
            Unmerged_Sizes = self.Runs.GetUnmergedDataSizes();
        end
        function Merged_Sizes = MergeDataSizes(self,Unmerged_Sizes);
            Current_Map = Unmerged_Sizes{1}{1};
            for Run_Index = 1:numel(Unmerged_Sizes);
                for Region_Index = 1:numel(Unmerged_Sizes{Run_Index});
                    if size(Unmerged_Sizes{Run_Index}{Region_Index},1)>size(Current_Map,1);
                        Current_Map = Unmerged_Sizes{Run_Index}{Region_Index};
                    end
                end
            end
            Merged_Sizes = Current_Map;
        end
        function Merged_Sizes = GetMergedDataSizes(self);
            Unmerged_Sizes = self.GetUnmergedDataSizes();
            Merged_Sizes = self.MergeDataSizes(Unmerged_Sizes);
        end
        
        function Cores = GetCores(self);
            Cores = self.Runs.GetCores();
        end
        function Solvers = GetSolvers(self);
            Solvers = self.Runs.GetSolvers();
        end
        
        function Unmerged_Dimension_Maps = GetUnmergedDimensionMaps(self);
            Unmerged_Dimension_Maps = self.Runs.GetUnmergedDimensionMaps();
        end
        function Merged_Dimension_Map = MergeDimensionMaps(self,Unmerged_Dimension_Maps);
            Merged_Map = containers.Map();            
            for Run_Index = 1:numel(self.Runs);
                for Region_Index = 1:numel(self.Runs(Run_Index).Regions);
                    Current_Dimension_Map = Unmerged_Dimension_Maps{Run_Index}{Region_Index};
                    Current_Keys = keys(Current_Dimension_Map);
                    Current_Values = values(Current_Dimension_Map);
                    
                    for Key_Index = 1:numel(Current_Keys);
                        if ~isKey(Merged_Map,Current_Keys{Key_Index});
                            Merged_Map(Current_Keys{Key_Index}) = Current_Values{Key_Index};
                        elseif isKey(Merged_Map,Current_Keys{Key_Index});
                            Current_Sizes = Merged_Map(Current_Keys{Key_Index});
                            if Current_Values{Key_Index}{2}>Current_Sizes{2};
                                Merged_Map(Current_Keys{Key_Index}) = Current_Values{Key_Index};
                            end
                        end
                    end  
                end
            end
            Merged_Dimension_Map = Merged_Map;
        end
        function Merged_Dimension_Map = GetMergedDimensionMap(self);
            Unmerged_Dimension_Maps = self.GetUnmergedDimensionMaps();
            Merged_Dimension_Map = self.MergeDimensionMaps(Unmerged_Dimension_Maps);
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
        
        %% Saving
        function DeleteExistingFile(self); 
            if self.ShouldSaveFlag && self.SaveToSameFileFlag;
                if self.CheckFileExists(self.Information.Output_File);
                    delete(char(self.Information.Output_File));
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
            for Run_Index = 1:numel(self.Runs);
                Replication_Data{Run_Index} = self.Runs(Run_Index).MakeReplicationData();
            end
%             Replication_Data = vertcat(Replication_Data_Cells);
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
                for Run_Index = 1:numel(self.Runs);
                    for Region_Index = 1;
                        self.Runs(Run_Index).Regions(Region_Index).Conditions.Transients.UndealMatrix();
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
            File = self.Information.Output_File;
            Parameter_Group_Names = self.GetMergedParameterGroupNames();
            Parameter_Names = self.GetMergedParameterNames();
            
            Data_Names = self.GetMergedDataNames();
            Data_Size_Map = self.GetMergedDataSizes();
            
            Cores = self.GetCores();
            Solvers = self.GetSolvers();
            CoreSolver = {Cores,Solvers};
            
            Dimension_Map = self.GetMergedDimensionMap();
            
            Maximum_Data_Sizes = self.GetMaximumDimensionSizes();
            Replication_Data = self.MakeReplicationData();
            Model = self.Information.Model_Name;
            
            for Run_Index = 1:numel(self.Runs);
                Transient_Matrices{Run_Index} = self.Runs(Run_Index).Regions(1).Conditions.Transients.Matrix;
            end
            for Run_Index = 1:numel(self.Runs);
                Perturbation_Matrices{Run_Index} = self.Runs(Run_Index).Regions(1).Conditions.Perturbations.Matrix;
            end
            
            GECCO.PrepareNetCDF(File,Model,Data_Names,Maximum_Data_Sizes,Data_Size_Map,Parameter_Group_Names,Parameter_Names,Dimension_Map,Transient_Matrices,Perturbation_Matrices,Replication_Data,CoreSolver);
        end
        
        %%
        function UnpackData(self,Run_Index,Region_Index,Data,Dependents);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Atmosphere_CO2 = Data(1,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Algae = Data(2,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Phosphate = Data(3:4,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.DIC = Data(5:6,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Alkalinity = Data(7:8,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Atmosphere_Temperature = Data(9,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Ocean_Temperature = Data(10:11,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Silicate = Data(12,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Silicate_Weathering_Fraction = Data(13,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Carbonate_Weathering_Fraction = Data(14,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Radiation = Data(15,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Ice = Data(16,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Sea_Level = Data(17,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Snow_Line = Data(18,:);
            
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Time = Dependents(1,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Lysocline = Dependents(2,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Carbonate_Total = Dependents(3,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.Carbonate_Exposed = Dependents(4,:);
            self.Runs(Run_Index).Regions(Region_Index).Outputs.pH = Dependents(5:6,:);
            if size(Dependents,1)>6;
                self.Runs(Run_Index).Regions(Region_Index).Outputs.Cores = Dependents(7:end,:);
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
        
        %%
        function ParseGUIPerturbations(self,Perturbations);
            
        end        
        function ParseGUITransients(self,Transients);
            
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
        function LoadFinal(self,File);
%             if isempty(self.Information.Input_File);
%                 self.UpdateLogBox("Please select an input file");
%             elseif isempty(self);
%                 self.UpdateLogBox("Please instantiate the model first");
%             else
%                 Data = self.LoadData(self.Information.Input_File);
%                 if numel(self.Runs)==size(Data,3);
%                     for RunNumber = 1:numel(self.Runs);
%                         self.Model.Conditions(RunNumber).Initial.Conditions = Data(:,end,RunNumber);
%                         Lysocline = self.LoadLysocline(self.FileInputUI.String);
%                         self.Model.Conditions(RunNumber).Present.Lysocline = Lysocline(end);            
%                     end
%                 elseif numel(self.Runs)>size(Data,3);
%                     for RunNumber = 1:numel(self.Runs);
%                         self.Model.Conditions.Initial(RunNumber).Conditions = Data(end,:,1);
%                     end
%                     self.UpdateLogBox("More runs than initial conditions, used output from run 1");
%                 elseif numel(self.Runs)<size(Data,3);
                    for Run_Index = 1:numel(self.Runs);
                        Region_Index = 1;
                        self.Runs(Run_Index).Regions(Region_Index).Conditions.SetInitialMaxOutgassing(self.Runs(Run_Index).Chunks(end).Time_Out(2));
                        self.Runs(Run_Index).Regions(Region_Index).Conditions.Constants.Carbonate_Chemistry.Lysocline = [];
                        self.Runs(Run_Index).Regions(Region_Index).Conditions.Initials.LoadFinal(File);
                        self.Runs(Run_Index).Regions(Region_Index).Conditions.Initials.Undeal();
                    end
%                     self.UpdateLogBox("More initial conditions than runs");
%                 end
%             end
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
