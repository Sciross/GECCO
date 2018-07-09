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
            DirectoryContentsModelsFull = dir([self.ModelDirectory,'..\*_Model*']);
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
        function Unmerged_Names = GetUnmergedParameterNames(self);
            for Self_Index = 1:numel(self);
                Unmerged_Names{Self_Index} = self(Self_Index).Regions.GetParameterNames();
            end
        end
        
        %% Save
        function SelfPrepareNetCDF(self);
            File = self.Information.Output_File;
            Parameter_Group_Names = self.Regions(1).Conditions.GetShallowNames(self.Runs(1).Regions(1).Conditions.Constants);
            Parameter_Names = self.Regions(1).Conditions.GetDeepNames(self.Runs(1).Regions(1).Conditions.Constants);
            Maximum_Data_Sizes = self.GetMaximumDimensionSizes();
            Dimension_Map = self.Regions(1).Conditions.Presents.DimensionMap;
            Data_Names = properties(self.Regions(1).Outputs);
            Data_Size_Map = self.Regions(1).Outputs.Data_Size_Map;
            Replication_Data = self.MakeReplicationData();
            Model = self.Information.Model_Name;
            Core = char(self.Regions(1).Conditions.Functionals.Core);
            Solver = char(self.Regions(1).Conditions.Functionals.Solver);
            CoreSolver = {Core,Solver};
            for Region_Index = 1:numel(self.Regions);
                Transient_Matrices{Region_Index} = self.Regions(Region_Index).Conditions.Transients.Matrix;
            end
            for Region_Index = 1:numel(self.Regions);
                Perturbation_Matrices{Region_Index} = self.Regions(Region_Index).Conditions.Perturbations.Matrix;
            end
            
            GECCO.PrepareNetCDF(File,Model,Data_Names,Maximum_Data_Sizes,Data_Size_Map,Parameter_Group_Names,Parameter_Names,Dimension_Map,Transient_Matrices,Perturbation_Matrices,Replication_Data,CoreSolver);
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