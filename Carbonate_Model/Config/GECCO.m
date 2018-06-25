classdef GECCO < matlab.mixin.Copyable
    properties
        Architectures
        Conditions
        Data
        Time
        Lysocline
        Model
        Solver
        Core
    end
    properties (Hidden = true)
        DimensionMap
        DataNames
        DataOutLen
        ModelFcn
        SolverFcn
        CoreFcn
    end
    methods
        %% Constructor method
        function self = GECCO(Architectures,Conditions)
            % Take input arguments if given
            if nargin~=0;
                self.Architectures = Architectures;
                self.Conditions = Conditions;
            % Otherwise instantiate a default architecture
            else
            end
        end
        %% Create an architecture
        function AddArchitecture(self,Architecture);
            self.Architectures = [self.Architectures,Architecture];
        end
        
        %% Create a condition
        function AddCondition(self,Condition);
            self.Conditions = [self.Conditions,Condition];
        end
        
        %% Add output data to GECCO Object
        function AddData(self,Data,Run,Chunk);
            self.Data{Chunk,Run} = Data;
        end
        
        %% Add time data to GECCO object
        function AddTime(self,Time,Run,Chunk);
            self.Time{Chunk,Run} = Time;
        end
        
        %% Add constants to GECCO object   
        % Adds the constants to the model object
            % That includes the dimensional matching of values with a 'd'
            % dimension (so two element vectors will become matrices with
            % first dimension size of two).
            
        % ##MAY be a conflict where parameter depth number is needed as
        % this is not propagated with the uniques!
        function AddConst(self,ConstRuns);
            if ~isempty(ConstRuns);
                Names = self.Name;
                UniqueNames = unique(Names,'stable');
                
                for Parameter = 1:numel(UniqueNames);
                    if numel(self.Conditions.Constant.(UniqueNames{Parameter}))==1;
                        self.Conditions.Constant.(UniqueNames{Parameter}) = ConstRuns(:,Parameter);
                    elseif numel(self.Conditions.Constant.(UniqueNames{Parameter}))==2 && sum(strcmp(Names,Names{Parameter}))==1;
                        Temp = self.Conditions.Constant.(UniqueNames{Parameter})(3-self.Conditions.Variable{Parameter,2});
                        TempRightLength = repelem(Temp,numel(ConstRuns(:,Parameter)));
                        if self.Conditions.Variable{Parameter,2} == 1;
                            Variable = [ConstRuns(:,Parameter)';TempRightLength];
                        elseif self.Conditions.Variable{Parameter,2} == 2;
                            Variable = [TempRightLength;ConstRuns(:,Parameter)'];
                        end
                        self.Conditions.Constant.(UniqueNames{Parameter}) = Variable;
                    elseif numel(self.Conditions.Constant.(UniqueNames{Parameter}))==2 && sum(strcmp(Names,Names{Parameter}))==2;
                        Indices = find(strcmp(Names,UniqueNames{Parameter}));
                        self.Conditions.Constant.(UniqueNames{Parameter}) = ConstRuns(:,Indices)';
                    end
                end
            end
        end
        
        function CalculateDependents(self,Run);
            [self.Conditions.Present.pH,self.Conditions.Present.CO2,~,~,self.Conditions.Present.OmegaC,~] = CarbonateChemistry_Iter(self.Conditions.Present,[self.Conditions.Initial.Conditions(5);self.Conditions.Initial.Conditions(6)],[self.Conditions.Initial.Conditions(7);self.Conditions.Initial.Conditions(8)],[10^(-8.1);10^(-8.1)],self.Conditions.Present.CarbonateConstants);
            self.Conditions.Present.HIn = (10.^(-self.Conditions.Present.pH))*1000;
            self.Conditions.Present.Lysocline = CalculateLysocline_Fun_RegulaFalsi_Full_Iter(self,self.Conditions.Initial.DIC(2));
        end
                
        %% Return Names
        % Specifically goes through Variables which are in cells and
        % returns the names
        function Names = Name(self);
            for n = 1:size(self.Conditions.Variable,1);
                Names{n} = self.Conditions.Variable{n,1}{1};
            end
        end
        
        %% Parallel operations
        % Split the model by run
        function ModelCell = Split(self);
            % Get total runs
            RunNumber = size(self.Conditions.Constant,2);
            % Preallocate the models
            ModelCell = cell(1,RunNumber);
            for n = 1:RunNumber;
                % Produce a deep copy of the objects
                A = copy(self.Architectures);
                B = copy(self.Conditions);
                
                % Instatiate a new model with the copied conditions
                ModelCell{1,n} = GECCO(A,B);
                % Set the constant + initial conditions to match
                ModelCell{1,n}.Conditions.Constant = ModelCell{1,n}.Conditions.Constant(n);
                ModelCell{1,n}.Conditions.Initial = ModelCell{1,n}.Conditions.Initial(n);
                % Ensure each has a dimensional map copy
                ModelCell{1,n}.DimensionMap = self.DimensionMap;
                
                % Copy over additional attributes
                ModelCell{1,n}.Model = self.Model;
                ModelCell{1,n}.Solver = self.Solver;
                ModelCell{1,n}.Core = self.Core;
                
                % Update the present conditions ##NEEDED?
                ModelCell{1,n}.Conditions.UpdatePresent;
            end
        end
        
        % Remerge the model by run
        function Merge(self,ModelCell);
            % Get the number of values that are to be input
            Elements = self.Count(ModelCell);
            % Get the maximum number of values for preallocation
            MaxElements = max(Elements);
            % Preallocate
            Time = NaN(MaxElements,1,numel(ModelCell));
            Data = NaN(MaxElements,8,numel(ModelCell));
            Lysocline = NaN(MaxElements,1,numel(ModelCell));
            
            % Loop through each run and build time/data/constants matrix
            for ModelNumber = 1:numel(ModelCell);
                Time(1:Elements(ModelNumber),:,ModelNumber) = ModelCell{ModelNumber}.Time;
                Data(1:Elements(ModelNumber),:,ModelNumber) = ModelCell{ModelNumber}.Data;
                Lysocline(1:Elements(ModelNumber),:,ModelNumber) = ModelCell{ModelNumber}.Lysocline;
                Constants(ModelNumber) = ModelCell{ModelNumber}.Conditions.Constant;
            end
            
            % Finally assign the matrix to the relevant object property
            self.Time = Time;
            self.Data = Data;
            self.Lysocline = Lysocline;
            self.Conditions.Constant = Constants; 
        end
        
        %% Counts the number of elements of specific vectors in cells
        function Elements = Count(self,ModelCell);
            for ModelNumber = 1:numel(ModelCell);
                Elements(ModelNumber) = numel(ModelCell{ModelNumber}.Time);
            end
        end
        
        %% Constant processing
        % Returns constant names with specific names removed
        function ConstNamesClean = GetCleanConstNames(self);
            ConstNames = fieldnames(self.Conditions.Constant);
            RemovedNames = {'PressureCorrection','k0_Matrix','k1_Matrix','k2_Matrix','kb_Matrix','kw_Matrix','ksp_cal_Matrix','ksp_arag_Matrix','ks_Matrix','FitMatrix'};
            VarNames = self.GetVarNames;
            ConstNamesClean = setdiff(ConstNames,[RemovedNames;VarNames{:}]);
        end
        % Returns the variable names
        function VarNames = GetVarNames(self);
            if iscell(self.Conditions.Variable);
                for n = 1:size(self.Conditions.Variable,1);
                    VarNames{n} = self.Conditions.Variable{n,1};
                end
            else
                VarNames = {};
            end
        end
        
        % Produces a dimensional map of the constants
        function ConstDimensionMap(self);
            % Keys are the fieldnames
            Keys = fieldnames(self.Conditions.Constant);
            % Loop through each key
            for Parameter = 1:numel(Keys);
                % Get the size
                ParameterSize{Parameter} = size(self.Conditions.Constant(1).(Keys{Parameter}));
                
                % Assign the 'a' or 'd' dimension
                if ParameterSize{Parameter}(1)==1;
                    Dimension1 = {'a'};
                elseif ParameterSize{Parameter}(1)==2;
                    Dimension1 = {'d'};
                end
                
                % Assign constant, special cases covered by _VAL
                if ParameterSize{Parameter}(2)==1;
                    Dimension2 = {'k'};
                else
                    Dimension2 = {['k_',num2str(ParameterSize{Parameter}(2))]};
                end
                
                % Third dimension is the number of runs
                Dimension3 = 'r'; % {numel(self.Conditions.Constant)};
                
                % Concatenate the dimensional values
                Values{Parameter} = [Dimension1,Dimension2,Dimension3];
            end
            % Create the map object
            self.DimensionMap = containers.Map(Keys,Values);
        end
        
        % Updates the dimensional map to include variables
        function UpdateConstantMap(self);
            % Loop through each Variable and assign the second dimension as
            % 't' instead of 'k'
            for Parameter = 1:size(self.Conditions.Variable,1);
                Dimensions = self.DimensionMap(self.Conditions.Variable{Parameter,1}{1});
                Dimensions{2} = 't';
                self.DimensionMap(self.Conditions.Variable{Parameter,1}{1}) = Dimensions;
            end
        end
        
        %% Convert the output data to a matrix
%         function MatrifyData(self);
%             Length = sum(cellfun('length',self.Data),1);
%             TimeMat = NaN(max(Length),1,size(self.Time,2));
%             DataMat = NaN(max(Length),numel(self.Conditions.Initial.Conditions),size(self.Data,2));
%             
%             for Run = 1:size(self.Data,2);
%                 TimeMat(1:Length(Run),1,Run) = cell2mat(self.Time(:,Run));
%                 DataMat(1:Length(Run),1:numel(self.Conditions.Initial.Conditions),Run) = cell2mat(self.Data(:,Run));
%             end
%             self.Time = TimeMat;
%             self.Data = DataMat;
%         end
        
%         function MatrifyData_Par(self,Time,Data);
%             for n = 1:numel(Data);
%                 DataT{n} = vertcat(Data{n}{:});
%                 TimeT{n} = vertcat(Time{n}{:});
%             end
%             Length = sum(cellfun('length',DataT),1);
%             TimeMat = NaN(max(Length),1,size(Time,2));
%             DataMat = NaN(max(Length),size(DataT{1},2),size(Data,2));
%             
%             for Run = 1:numel(DataT);
%                 TimeMat(1:Length(Run),1,Run) = cell2mat(TimeT(Run));
%                 DataMat(1:Length(Run),1:size(DataT{1},2),Run) = cell2mat(DataT(Run));
%             end
%             self.Time = TimeMat;
%             self.Data = DataMat;
%         end
%         
        %% Save the output data
%         function SaveData(self,Filename);
%             Deflate = 5;
%             Format = 'netcdf4_classic';
%             
%             Names = {'Time','Atmosphere.CO2','Algae','Phosphate','DIC','Alkalinity'};
%             Time = self.Time;
%             Atmosphere.CO2 = self.Data(:,1,:);
%             Algae = self.Data(:,2,:);
%             Phosphate = self.Data(:,3:4,:);
%             DIC = self.Data(:,5:6,:);
%             Alkalinity = self.Data(:,7:8,:);
%             
%             UserInput = ncsave_OO(Filename,Names,Format,Deflate);
%             
%             ConstNames = fieldnames(self.Conditions.Constant);
%             ncadd_OO(self,Filename,ConstNames,Format,Deflate,UserInput);
%         end
        
        %% Saving Data
%         function TotalPerts = GetTotalPerts(self,Runs);
%             PertNumber = 0;
%             for RunIndex = 1:numel(Runs);
%                 ChunkNumber = numel(Runs(RunIndex).Chunks);
%                 for ChunkIndex = 1:ChunkNumber;
%                     PertNumber = PertNumber+size(Runs(RunIndex).Chunks(ChunkIndex).Perturbations,1);
%                 end
%             end
%             TotalPerts = PertNumber;
%         end
        function CreateFile(self,Filename);
            NETCDF4 = netcdf.getConstant('NETCDF4');
            NOCLOBBER = netcdf.getConstant('NC_NOCLOBBER');
            CreateMode = bitor(NETCDF4,NOCLOBBER);
            FileID = netcdf.create(Filename,CreateMode);
            netcdf.close(FileID);
        end
        function CreateGroups(self,Filename);
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            ConstGrpID = netcdf.defGrp(FileID,'Constants');
            VarGrpID = netcdf.defGrp(FileID,'Variables');
            DataGrpID = netcdf.defGrp(FileID,'Data');
            ArchGrpID = netcdf.defGrp(FileID,'Architectures');
            
            netcdf.close(FileID);
        end
        function DefineDimensions(self,Filename,Runs);            
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            Dimt = {'t',max(Runs.Count)};
            Dimr = {'r',numel(Runs)};
            Dima = {'a',1};
            Dimd = {'d',2};
            Dimk = {'k',1};
            
            netcdf.defDim(FileID,Dima{1},Dima{2});
            netcdf.defDim(FileID,Dimd{1},Dimd{2});
            
            netcdf.defDim(FileID,Dimk{1},Dimk{2});
            netcdf.defDim(FileID,'k_13',13);
            netcdf.defDim(FileID,'k_1000',1000);
            netcdf.defDim(FileID,Dimt{1},Dimt{2});
            
            netcdf.defDim(FileID,Dimr{1},Dimr{2});
            
            netcdf.close(FileID);
        end
        function DefineVariables(self,Filename);
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            ConstGrpID = netcdf.inqNcid(FileID,'Constants');
            VarGrpID = netcdf.inqNcid(FileID,'Variables');
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            ArchGrpID = netcdf.inqNcid(FileID,'Architectures');
            
            % Constants
            ConstNames = self.GetCleanConstNames;
            for n = 1:numel(ConstNames);
                CurrentDims = self.DimensionMap(ConstNames{n});
                VarID = netcdf.defVar(ConstGrpID,ConstNames{n},'double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2}),netcdf.inqDimID(FileID,CurrentDims{3})]);
                netcdf.defVarFill(ConstGrpID,VarID,false,NaN);
            end
            
            % Time
            DataDims1 = {'a','t','r'};
            DataDims2 = {'d','t','r'};
            
            CurrentDims = DataDims1;
            VarID = netcdf.defVar(DataGrpID,'Time','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2}),netcdf.inqDimID(FileID,CurrentDims{3})]);
            netcdf.defVarFill(DataGrpID,VarID,false,NaN);
            
            % Data
            for n = 1:2;
                CurrentDims = DataDims1;
                VarID = netcdf.defVar(DataGrpID,self.DataNames{n},'double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2}),netcdf.inqDimID(FileID,CurrentDims{3})]);
                netcdf.defVarFill(DataGrpID,VarID,false,NaN);
            end
            
            VarID = netcdf.defVar(DataGrpID,'Lysocline','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,'t'),netcdf.inqDimID(FileID,CurrentDims{3})]);
            netcdf.defVarFill(DataGrpID,VarID,false,NaN);
            
            for n = 3:5;
                CurrentDims = DataDims2;
                VarID = netcdf.defVar(DataGrpID,self.DataNames{n},'double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2}),netcdf.inqDimID(FileID,CurrentDims{3})]);
                netcdf.defVarFill(DataGrpID,VarID,false,NaN);
            end
            
            % Variables
            VarNames = self.GetVarNames;
            for n = 1:numel(VarNames);
                CurrentDims = self.DimensionMap(VarNames{n}{1});
                VarID = netcdf.defVar(VarGrpID,VarNames{n}{1},'double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,'t'),netcdf.inqDimID(FileID,CurrentDims{3})]);
                netcdf.defVarFill(VarGrpID,VarID,false,NaN);
            end
            
            CurrentDims = {'d','a'};
            % Architectures
            VarID = netcdf.defVar(ArchGrpID,'BoxDepths','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2})]);
            netcdf.defVarFill(ArchGrpID,VarID,false,NaN);
            
            VarID = netcdf.defVar(ArchGrpID,'BoxArea','double',[netcdf.inqDimID(FileID,CurrentDims{2})]);
            netcdf.defVarFill(ArchGrpID,VarID,false,NaN);
            
            netcdf.close(FileID);
        end
        function PrepareNetCDF(self,Filename,Runs);
            self.ConstDimensionMap;
            self.UpdateConstantMap;
            self.CreateFile(Filename);
            self.CreateGroups(Filename);
            self.DefineDimensions(Filename,Runs);
            self.DefineVariables(Filename);
        end

        % Save data
        function SaveData(self,Filename,Run);
            FileID = netcdf.open(Filename,'WRITE');
            
            % Specify start and stride
            Start = [0,0,Run-1];
            Count = [1,size(self.Data,1),1];
            Stride = [1,1,1];
            
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            TimeID = netcdf.inqVarID(DataGrpID,'Time');
            
            % Write time to file
            netcdf.putVar(DataGrpID,TimeID,Start,Count,self.Time');
            
            % First loop for values with dimension 'a'
            for n = 1:2;
                netcdf.putVar(DataGrpID,netcdf.inqVarID(DataGrpID,self.DataNames{n}),Start,Count,Stride,self.Data(:,n)');
            end
            % Second loop for values with dimension 'd'
            Count(1) = 2;
            for n = 3:5;
                netcdf.putVar(DataGrpID,netcdf.inqVarID(DataGrpID,self.DataNames{n}),Start,Count,Stride,self.Data(:,((2*n)-3):((2*n)-2))');
            end            
            netcdf.close(FileID);
        end
        function SaveConstants(self,Filename,Run);
            % Open file
            FileID = netcdf.open(Filename,'WRITE');
            
            % Specify start and stride
            Start = [0,0,Run-1];
            Stride = [1,1,1];
            
            % Get ID of appropriate group
            ConstGrpID = netcdf.inqNcid(FileID,'Constants');
            % Get names of constants
            ConstNamesClean = self.GetCleanConstNames;
            
            for n = 1:numel(ConstNamesClean);
                Count = [size(self.Conditions.Constant.(ConstNamesClean{n})),1];
                netcdf.putVar(ConstGrpID,netcdf.inqVarID(ConstGrpID,ConstNamesClean{n}),Start,Count,Stride,self.Conditions.Constant.(ConstNamesClean{n}));
            end
            
            netcdf.close(FileID);
        end
        function SaveVariables(self,Filename,Run);
            % Open file
            FileID = netcdf.open(Filename,'WRITE');
            
            % Specify start and stride
            Start = [0,0,Run-1];
            Stride = [1,1,1];
            
            % Get ID of appropriate group
            VarGrpID = netcdf.inqNcid(FileID,'Variables');
            % Get names of constants
            VarNames = self.GetVarNames;
            
            for n = 1:numel(VarNames);
                Count = [size(self.Conditions.Constant.(VarNames{n}{1})'),1];
                netcdf.putVar(VarGrpID,netcdf.inqVarID(VarGrpID,VarNames{n}{1}),Start,Count,Stride,(self.Conditions.Constant.(VarNames{n}{1}))');
            end
            
            netcdf.close(FileID);
        end
        function SaveDependents(self,Filename,Run);
            % Open file
            FileID = netcdf.open(Filename,'WRITE');
            
            % Specify start and stride
            Start = [0,0,Run-1];
            Stride = [1,1,1];
            
            % Get ID of appropriate group
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            % Get names of constants
            VarNames = {'Lysocline'};
            
            for n = 1:numel(VarNames);
            Count = [size(self.(VarNames{n})'),1];
                netcdf.putVar(DataGrpID,netcdf.inqVarID(DataGrpID,VarNames{n}),Start,Count,Stride,self.(VarNames{n})');
            end
            
            netcdf.close(FileID);
        end
        function SaveAttributes(self,Filename,Run);
            % Open file
            FileID = netcdf.open(Filename,'WRITE');
            
            % Enter define mode
            netcdf.reDef(FileID);
            
            % Get global ID
            GlobalID = netcdf.getConstant('GLOBAL');
            
            % Save attributes
            netcdf.putAtt(FileID,GlobalID,'Model',self.Model);
            netcdf.putAtt(FileID,GlobalID,'Core',self.Core);
            netcdf.putAtt(FileID,GlobalID,'Solver',self.Solver);
            
            netcdf.close(FileID);
            
        end
        function SaveArchitectures(self,Filename,Run);
            % Open file
            FileID = netcdf.open(Filename,'WRITE');
            % Get group ID
            ArchGrpID = netcdf.inqNcid(FileID,'Architectures');
            % Put data in
            Start = [0,0,Run-1];
            Stride = [1,1,1];
 
            netcdf.putVar(ArchGrpID,netcdf.inqVarID(ArchGrpID,'BoxDepths'),self.Architectures.BoxDepths);
            netcdf.putVar(ArchGrpID,netcdf.inqVarID(ArchGrpID,'BoxArea'),self.Architectures.BoxArea);
            netcdf.close(FileID);
        end
        function Save(self,Filename,Run);
            self.SaveData(Filename,Run);
            self.SaveConstants(Filename,Run);
            self.SaveVariables(Filename,Run);
            self.SaveDependents(Filename,Run);
            self.SaveAttributes(Filename,Run);
            self.SaveArchitectures(Filename,Run);
        end
        
        %% Loading Data
        function LoadData(self,Filename,WhatToLoad);
%             ncread(source,varname,start,count,stride);
            if strcmp(WhatToLoad,'Time')==1;
                self.Time = ncread(Filename,'Time');
            end
            if strcmp(WhatToLoad,'Data');
                CO2 = ncread(Filename,'Atmosphere_CO2');
                Algae = ncread(Filename,'Algae');
                Phosphate = ncread(Filename,'Phosphate');
                DIC = ncread(Filename,'DIC');
                Alkalinity = ncread(Filename,'Alkalinity');
               
                self.Data = [CO2;Algae;Phosphate;DIC;Alkalinity];
            end
        end
    end
end