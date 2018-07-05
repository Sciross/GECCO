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
                Timestep_Chunks(Chunk_Index) = numel(self.Chunks(Chunk_Index).TimeOut(1):self.Chunks(Chunk_Index).TimeOut(3):self.Chunks(Chunk_Index).TimeOut(2));
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
        
        %% Save
        function SelfPrepareNetCDF(self);
            GECCO.PrepareNetCDF(self.Information.OutputFile,self.GetMaximumDimensionSizes(),self.Regions(1).Conditions.Constants.DimensionMap,self.DataIndices,self.DataNames,self.Runs(1).Regions(1).Conditions.GetVarNames(),self.MakeReplicationData());
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