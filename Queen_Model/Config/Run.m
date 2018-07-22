classdef Run < handle
    properties
        Chunks@Chunk
        Regions@Region
        Information@Information
        Interactions     
    end
    properties (Hidden=true)
        Model
        ModelDirectory
        InstalledModels
    end
    methods
        % Constructor
        function self = Run(Chunks,Regions);
            Model_Filepath = which('GUI.m');
            Model_Dir = Model_Filepath(1:end-12);
            self.ModelDirectory = Model_Dir;
            
            % Path
            self.SetInstalledModels();
            self.SetModel("Queen_Model");
            self.AddModelToPath();
                
            if nargin==2;                
                self.Chunks = Chunks;
                self.Regions = Regions;
            else
                self.Chunks = Chunk();
                self.Regions = Region();
            end
            self.Information = Information();
        end
        % Adds model to path
        function AddModelToPath(self)
            addpath(genpath(char(strcat(self.ModelDirectory,"../",self.Model))));
        end
        % Removes model from path
        function RemoveModelFromPath(self,src,event);
            if ~isempty(self.ModelOnPath);
                rmpath(genpath(['./../../',self.ModelOnPath]));
            end
        end
        
        %% Gets available models
        function InstalledModels = GetInstalledModels(self,src,event);
            % Looks for directory contents matching pattern
            DirectoryContentsModelsFull = dir([self.ModelDirectory,'../*_Model*']);
            % Concatenates the names from the struct
            InstalledModels = vertcat({DirectoryContentsModelsFull(:).name});
        end
        function SetInstalledModels(self);
            self.InstalledModels = self.GetInstalledModels();
        end
        function SetModel(self,Model);
            if ~isstring(Model);
                Model = string(Model);
            end
            if any(self.InstalledModels==Model);
                self.Model = Model;
            end
        end
        
        %% Addition methods
        function self = AddRun(self,TimeIn,TimeOut);
            if nargin==3;
                if isempty(self);
                    self = Run(Chunk(TimeIn,TimeOut));
                else
                    self = [self,Run(Chunk(TimeIn,TimeOut))];
                end
            else
                if isempty(self);
                    self = Run();
                else
                    self = [self,Run()];
                end
            end
        end   
        
        function AddChunk(self,ChunkIn);
            if nargin>1;
                self.Chunks = [self.Chunks,ChunkIn];
            else
                if numel(self.Chunks)>0;
                    Length = self.Chunks(end).TimeIn(2)-self.Chunks(end).TimeIn(1);
                    self.Chunks = [self.Chunks,Chunk([self.Chunks(end).TimeIn(2),self.Chunks(end).TimeIn(2)+Length,self.Chunks(end).TimeIn(3)],[self.Chunks(end).TimeIn(2),self.Chunks(end).TimeIn(2)+Length,self.Chunks(end).TimeOut(3)])];
                else
                    self.Chunks = [self.Chunks,Chunk()];
                end
            end
        end        
        function RemoveChunk(self,ChunkNumber);
            self.Chunks = [self.Chunks(1:ChunkNumber-1),self.Chunks(ChunkNumber+1:end)];
        end
        
        function AddPerturbation(self,PerturbWhat,WhatTo);
            self.Perturbations = [self.Perturbations;{PerturbWhat,WhatTo}];        
        end
        function AddRegion(self);
            self.Regions = self.Regions.AddRegion();
        end
        
        %%
        function Timesteps = GetTimestepCount(self);
            for Chunk_Index = 1:numel(self.Chunks);
                Timestep_Chunks(Chunk_Index) = numel(self.Chunks(Chunk_Index).TimeIn(1):self.Chunks(Chunk_Index).TimeIn(3):self.Chunks(Chunk_Index).TimeIn(2));
            end
            Timesteps = sum(Timestep_Chunks);
        end
        function Timesteps = GetOutputTimestepCount(self);
            for Chunk_Index = 1:numel(self.Chunks);
                Timestep_Chunks(Chunk_Index) = numel(self.Chunks(Chunk_Index).Time_Out(1):self.Chunks(Chunk_Index).Time_Out(3):self.Chunks(Chunk_Index).Time_Out(2));
            end
            Timesteps = sum(Timestep_Chunks);
        end
        
        %% Validation
        function Flag = Validate(self);
            for ChunkIndex = 1:numel(self.Chunks);
                if ChunkIndex == numel(self.Chunks);
                    Flag = 1;
                    break;
                else
                    TimeOutEnd = self.Chunks(ChunkIndex).TimeOut(2);
                    TimeOutStart = self.Chunks(ChunkIndex+1).TimeOut(1);
                    
                    if TimeOutStart~=TimeOutEnd;
                        Flag = 0;
                        if nargin>1;
                             end
                    end
                end
            end
        end        
        function Replication_Data = MakeReplicationData(self);
            Replication_Data = self.Regions(1).MakeReplicationData(self);
        end
        
        %% Merging
        function Unmerged_Names = GetUnmergedParameterGroupNames(self);
            for Self_Index = 1:numel(self);
                Unmerged_Names{Self_Index} = self(Self_Index).Regions.GetParameterGroupNames();
            end
        end
        function Merged_Names = MergeParameterGroupNames(self,Unmerged_Names);
            Names = "";
            for Region_Index = 1:numel(Unmerged_Names{1});
                Names = [Names;Unmerged_Names{1}{Region_Index}];
            end
            Unique_Names = unique(Names,'stable');
            Merged_Names = Unique_Names(~strcmp(Unique_Names,""));
        end
        function Merged_Names = GetMergedParameterGroupNames(self);            
            Unmerged_Names = self.GetUnmergedParameterGroupNames();
            Merged_Names = self.MergeParameterGroupNames(Unmerged_Names);
        end
        
        function Unmerged_Names = GetUnmergedParameterNames(self);
            for Self_Index = 1:numel(self);
                Unmerged_Names{Self_Index} = self(Self_Index).Regions.GetParameterNames();
            end
        end
        function Merged_Names = MergeParameterNames(self,Unmerged_Names);
            % Get maximum size
            for Region_Index = 1:numel(Unmerged_Names);
                Sizes(Region_Index) = numel(Unmerged_Names{1}{Region_Index});
            end
            Maximum_Group_Number = max(Sizes(:));
            
            Names = cell(1,Maximum_Group_Number);
            for Region_Index = 1:numel(Unmerged_Names{1});
                for Group_Index = 1:numel(Unmerged_Names{1}{Region_Index});
                    if isempty(Names{Group_Index});
                        Names{Group_Index} = "";
                    end
                    Names{Group_Index} = [Names{Group_Index};Unmerged_Names{1}{Region_Index}{Group_Index}];
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
            for Self_Index = 1:numel(self);
                Unmerged_Names{Self_Index} = self(Self_Index).Regions.GetDataNames();
            end
        end
        function Merged_Names = MergeDataNames(self,Unmerged_Names);
            Names = "";
            for Region_Index = 1:numel(Unmerged_Names{1});
                Names = [Names;Unmerged_Names{1}{Region_Index}];
            end
            Merged_Names = unique(Names);
            Merged_Names = Merged_Names(~strcmp(Merged_Names,""));
        end
        function Merged_Names = GetMergedDataNames(self);
            Unmerged_Names = self.GetUnmergedDataNames();
            Merged_Names = self.MergeDataNames(Unmerged_Names);
        end
        
        function Unmerged_Sizes = GetUnmergedDataSizes(self);
            for Self_Index = 1:numel(self);
                Unmerged_Sizes{Self_Index} = self(Self_Index).Regions.GetDataSizes();
            end
        end
        function Merged_Sizes = MergeDataSizes(self,Unmerged_Sizes);
            Current_Map = Unmerged_Sizes{1}{1};
            for Region_Index = 1:numel(Unmerged_Sizes);
                if size(Unmerged_Sizes{1}{Region_Index},1)>size(Current_Map,1);
                    Current_Map = Unmerged_Sizes{Region_Index};
                end
            end
            Merged_Sizes = Current_Map;
        end
        function Merged_Sizes = GetMergedDataSizes(self);
            Unmerged_Sizes = self.GetUnmergedDataSizes();
            Merged_Sizes = self.MergeDataSizes(Unmerged_Sizes);
        end
        
        function Cores = GetCores(self);
            for Self_Index = 1:numel(self);
                Cores{Self_Index} = self(Self_Index).Regions.GetCores();
            end
        end
        function Solvers = GetSolvers(self);
            for Self_Index = 1:numel(self);
                Solvers{Self_Index} = self(Self_Index).Regions.GetSolvers();
            end
        end
        
        function Unmerged_Dimension_Maps = GetUnmergedDimensionMaps(self);
            for Self_Index = 1:numel(self);
                Unmerged_Dimension_Maps{Self_Index} = self(Self_Index).Regions.GetDimensionMaps();
            end
        end
        function Merged_Dimension_Map = MergeDimensionMaps(self,Unmerged_Dimension_Maps);
            Merged_Map = containers.Map();
            for Region_Index = 1:numel(self.Regions);
                Current_Dimension_Map = Unmerged_Dimension_Maps{1}{Region_Index};
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
            Merged_Dimension_Map = Merged_Map;
        end
        function Merged_Dimension_Map = GetMergedDimensionMap(self);
            Unmerged_Dimension_Maps = self.GetUnmergedDimensionMaps();
            Merged_Dimension_Map = self.MergeDimensionMaps(Unmerged_Dimension_Maps);
        end
        
%         function Sizes = GetSizeOf(self,Type,Group,Name);
%             if nargin<4;
%                 Name = Group;
%                 Group = "";
%             end
%             for Self_Index = 1:numel(self);
%                 Sizes{Self_Index} = self(Self_Index).Regions.GetSizeOf(Type,Group,Name);
%             end
%         end
        
        function Values = GetDimensionSizes(self);
            Values(1) = 1;
            Values(2) = max(self.GetOutputTimestepCount());
            Values(3) = self.GetMaximumChunkNumber();
            Values(4) = self.GetMaximumSizeOf("Initials","Conditions");
            Values(5) = self.GetMaximumSizeOf("Constants","Architecture","Hypsometric_Bin_Midpoints");
            Values(6) = self.GetMaximumSizeOf("Constants","Seafloor","Core_Depths"); %max(self.GetCoreDepthSize());
            Values(7) = self.GetMaximumSizeOf("Initials","Outgassing"); %max(self.GetOutgassingSize());
            Values(8) = self.GetMaximumSizeOf("Presents","Outgassing","Gauss"); %max(self.GetOutgassingGaussianSize());
        end
        function Maximum_Chunk_Number = GetMaximumChunkNumber(self);
            for Run_Index = 1:numel(self);
                Chunk_Number(Run_Index) = numel(self(Run_Index).Chunks);
            end
            Maximum_Chunk_Number = max(Chunk_Number);
        end
        function Sizes = GetSizeOf(self,Type,Group,Name);
            if nargin<4;
                Name = Group;
                Group = "";
            end
            for Self_Index = 1:numel(self);
                Sizes(Self_Index) = self(Self_Index).Regions.GetSizeOf(Type,Group,Name);
            end
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
        
%         function SeafloorSizes = GetSeafloorSizes(self);
%             for Self_Index = 1:numel(self);
%                 SeafloorSizes{Self_Index} = self(Self_Index).Regions.GetSeafloorSizes();
%             end
%         end
%         function CoreDepthSizes = GetCoreDepthSizes(self);
%             for Self_Index = 1:numel(self);
%                 CoreDepthSizes{Self_Index} = self(Self_Index).Regions.GetCoreDepthSizes();
%             end
%         end
%         function OutgassingSizes = GetOutgassingSizes(self);
%             for Self_Index = 1:numel(self);
%                 OutgassingSizes{Self_Index} = self(Self_Index).Regions.GetOutgassingSizes();
%             end
%         end
%         function OutgassingGaussianSizes = GetOutgassingGaussianSizes(self);
%         end
%         function TimestepSizes = GetTimestepSizes(self);
%         end
%         function TimestepSizes = GetOutputTimestepSizes(self);
%         end
        
        %% Save
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
            
            Maximum_Data_Sizes = self.GetDimensionSizes();
            Replication_Data{1} = self.MakeReplicationData();
            Model = self.Information.Model_Name;
            
            Transient_Matrices = self.GetTransientMatrices();
            Perturbation_Matrices = self.GetPerturbationMatrices();            
            
            GECCO.PrepareNetCDF(File,Model,Data_Names,Maximum_Data_Sizes,Data_Size_Map,Parameter_Group_Names,Parameter_Names,Dimension_Map,Transient_Matrices,Perturbation_Matrices,Replication_Data,CoreSolver);
        end
       
        function Transient_Matrices = GetTransientMatrices(self);
            for Run_Index = 1:numel(self);
                Transient_Matrices{Run_Index} = self(Run_Index).Regions(1).Conditions.Transients.Matrix;
            end
        end
        function Perturbation_Matrices = GetPerturbationMatrices(self);
            for Run_Index = 1:numel(self);
                Perturbation_Matrices{Run_Index} = self(Run_Index).Regions(1).Conditions.Perturbations.Matrix;
            end
        end
        
        %% Load
        function Load(self,Filename);
            FileID = netcdf.open(Filename,'NOWRITE');
            RepGrpID = netcdf.inqNcid(FileID,'Replication');
            VarID = netcdf.inqVarID(RepGrpID,'Run_Matrix');
            [~,~,DimIDs,~] = netcdf.inqVar(RepGrpID,VarID);
            [Dim_Names,Dim_Sizes] = GECCO.DimIDToDim(FileID,DimIDs);            
            Run_Matrix = netcdf.getVar(RepGrpID,VarID);
            netcdf.close(FileID);
            
            for RunIndex = 2:size(Run_Matrix,1);
                TimeIn = Run_Matrix(RunIndex,3:5);
                TimeOut = Run_Matrix(RunIndex,6:8);
                if Run_Matrix(RunIndex,1)==numel(self.Runs);
                    self.Runs(Run_Matrix(RunIndex,1)).AddChunk(Chunk(TimeIn,TimeOut));
                else
                    self.Runs = self.Runs.AddRun(TimeIn,TimeOut,self.Model);
                end
            end
            
            for Run_Index = 1:numel(self);
            end
        end
        
    end
end