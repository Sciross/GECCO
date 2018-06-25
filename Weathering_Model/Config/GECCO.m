classdef GECCO < matlab.mixin.Copyable
    properties
        Architectures
        Conditions
        Data
        Time
        Lysocline
        Seafloor
        Outgassing
        Cores
        Seafloor_Total
        Model
        Solver
        Core
        Version
        Total_Steps
        Current_Step
        dt
    end
    properties (Hidden = true)
        DimensionMap
        DataNames
        DataOutLen
        ModelFcn
        SolverFcn
        CoreFcn
        OutEnd
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
                self.Architectures = Architecture();
                self.Conditions = Condition();
%                 self.DataNames = {'Atmosphere_CO2','Algae','Phosphate','DIC','Alkalinity'};
            end
            self.DataNames = {'Atmosphere_CO2';
                              'Algae';
                              'Phosphate';
                              'DIC';
                              'Alkalinity';
                              'Atmosphere_Temperature';
                              'Ocean_Temperature';
                              'Silicate';
                              'Carbonate';
                              'Silicate_Weathering_Fraction';
                              'Carbonate_Weathering_Fraction';
                              'Radiation'};
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
                        self.Conditions.Constant.(UniqueNames{Parameter}) = ConstRuns(Parameter,:);
                    elseif numel(self.Conditions.Constant.(UniqueNames{Parameter}))==2 && sum(strcmp(Names,Names{Parameter}))==1;
                        Temp = self.Conditions.Constant.(UniqueNames{Parameter})(3-self.Conditions.Variable{Parameter,2});
                        TempRightLength = repelem(Temp,numel(ConstRuns(Parameter,:)));
                        if self.Conditions.Variable{Parameter,2} == 1;
                            Variable = [ConstRuns(Parameter,:);TempRightLength];
                        elseif self.Conditions.Variable{Parameter,2} == 2;
                            Variable = [TempRightLength;ConstRuns(Parameter,:)];
                        end
                        self.Conditions.Constant.(UniqueNames{Parameter}) = Variable;
                    elseif numel(self.Conditions.Constant.(UniqueNames{Parameter}))==2 && sum(strcmp(Names,Names{Parameter}))==2;
                        Indices = find(strcmp(Names,UniqueNames{Parameter}));
                        self.Conditions.Constant.(UniqueNames{Parameter}) = ConstRuns(Indices,:);
                    end
                end
            end
        end
        
%         function CalculateDependents(self,Run);
%             [self.Conditions.Present.pH,self.Conditions.Present.CO2,~,~,self.Conditions.Present.OmegaC,~] = CarbonateChemistry_Iter(self.Conditions.Present,[self.Conditions.Initial.Conditions(5);self.Conditions.Initial.Conditions(6)],[self.Conditions.Initial.Conditions(7);self.Conditions.Initial.Conditions(8)],[10^(-8.1);10^(-8.1)],self.Conditions.Present.CCKs);
%             self.Conditions.Present.HIn = (10.^(-self.Conditions.Present.pH))*1000;
%             self.Conditions.Present.Lysocline = CalculateLysocline_Fun_RegulaFalsi_Full_Iter(self,self.Conditions.Initial.DIC(2),self.Conditions.Initial.Ocean_Temperature);
%         end
        
        %%
                
        %% Return Names
        % Specifically goes through Variables which are in cells and
        % returns the names
        function Names = Name(self);
            for n = 1:size(self.Conditions.Variable,1);
                Names{n} = self.Conditions.Variable{n,1}{1};
            end
        end
        
        %% Subduction
        function Max_Subduction = GetMaxSubduction(self);
            for Run_Index = 1:numel(self.Conditions);
                Max_Subduction(Run_Index) = numel(self.Conditions(Run_Index).Constant.Hypsometric_Bin_Midpoints);
            end
        end
        
        %% Outgassing
        function Out_End = GetOutgassingEnd(self,Runs);
            for Run_Index = 1:numel(Runs);
                Out_End(Run_Index) = Runs(Run_Index).Chunks(end).TimeIn(2)/self.Conditions(Run_Index).Constant.Outgassing_Temporal_Resolution;
            end
        end
        
        function Max_Outgassing = GetMaxOutgassing(self,Runs);
            for Run_Index = 1:numel(Runs);
                Max_Outgassing(Run_Index) = ceil(((self.Conditions(Run_Index).Constant.Outgassing_Mean_Lag)+(4.*self.Conditions(Run_Index).Constant.Outgassing_Spread)+(Runs(Run_Index).Chunks(end).TimeIn(2)))./self.Conditions(Run_Index).Constant.Outgassing_Temporal_Resolution);
            end
        end
        function Gauss_Elements = GetOutgassingGaussElements(self);
            for Run_Index = 1:numel(self.Conditions);
                Gauss_Elements(1,Run_Index) = numel(self.Conditions(Run_Index).Present.Outgassing_Gauss);
            end
        end
        function Initial_Outgassing_Length = GetInitialOutgassing(self,Runs);
            for Run_Index = 1:numel(Runs);
                Initial_Outgassing_Length(Run_Index) = numel(self.Conditions(Run_Index).Initial.Outgassing);
            end
        end
        
        %% Parallel operations
        % Split the model by run
        function ModelCell = Split(self);
            % Get total runs
            RunNumber = numel(self.Conditions);
            % Preallocate the models
            ModelCell = cell(1,RunNumber);
            for n = 1:RunNumber;
                % Produce a deep copy of the objects
                A = copy(self.Architectures);
                B = copy(self.Conditions);
                
                % Instatiate a new model with the copied conditions
                ModelCell{1,n} = GECCO(A,B);
                % Set the constant + initial conditions to match
                ModelCell{1,n}.Conditions = ModelCell{1,n}.Conditions(n);
                % Ensure each has a dimensional map copy
                ModelCell{1,n}.DimensionMap = self.DimensionMap;
                
                % Copy over additional attributes
                ModelCell{1,n}.Total_Steps = self.Total_Steps;
                ModelCell{1,n}.Current_Step = 0;
                ModelCell{1,n}.dt = self.dt;
                ModelCell{1,n}.Model = self.Model;
                ModelCell{1,n}.Solver = self.Solver;
                ModelCell{1,n}.Core = self.Core;
                ModelCell{1,n}.Seafloor = self.Seafloor;
                ModelCell{1,n}.Outgassing = self.Outgassing;
                
                % Update the present conditions ##NEEDED?
%                 ModelCell{1,n}.Conditions.UpdatePresent;
            end
        end
        
        % Remerge the model by run
        function Merge(self,ModelCell,Runs);
            % Get the number of values that are to be input
            Elements = self.Count(ModelCell);
            % Get the maximum number of values for preallocation
            MaxElements = max(Elements);
            % Also get maximum Outgassing
            OutElements = self.GetMaxOutgassing(Runs);
            % Preallocate
            Time = NaN(1,MaxElements,numel(ModelCell));
            Data = NaN(numel(ModelCell{1}.Conditions.Initial.Conditions),MaxElements,numel(ModelCell));
            Lysocline = NaN(1,MaxElements,numel(ModelCell));
            Outgassing = NaN(max(OutElements),1,numel(OutElements));
            
            % Loop through each run and build time/data/constants matrix
            for ModelNumber = 1:numel(ModelCell);
                Time(:,1:Elements(ModelNumber),ModelNumber) = ModelCell{ModelNumber}.Time;
                Data(:,1:Elements(ModelNumber),ModelNumber) = ModelCell{ModelNumber}.Data;
                Lysocline(:,1:Elements(ModelNumber),ModelNumber) = ModelCell{ModelNumber}.Lysocline;
                Constants(ModelNumber) = ModelCell{ModelNumber}.Conditions.Constant;
                Outgassing(1:OutElements(ModelNumber),:,ModelNumber) = ModelCell{ModelNumber}.Outgassing;
                Seafloor(:,:,ModelNumber) = ModelCell{ModelNumber}.Seafloor;
                Cores(:,:,ModelNumber) = ModelCell{ModelNumber}.Cores;
                Seafloor_Total(:,:,ModelNumber) = ModelCell{ModelNumber}.Seafloor_Total;
            end
            
            % Finally assign the matrix to the relevant object property
            self.Time = Time;
            self.Data = Data;
            self.Lysocline = Lysocline;
            self.Conditions.Constant = Constants; 
            self.Outgassing = Outgassing;
            self.Seafloor = Seafloor;
            self.Cores = Cores;
            self.Seafloor_Total = Seafloor_Total;
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
            ConstNames = fieldnames(self.Conditions(1).Constant);
            RemovedNames = {'Pressure_Correction','Hypsometric_Interpolation_Matrix','k0_Matrix','k1_Matrix','k2_Matrix','kb_Matrix','kw_Matrix','ksp_cal_Matrix','ksp_arag_Matrix','ks_Matrix'};
            VarNames = self.GetVarNames;
            ConstNamesClean = setdiff(ConstNames,[RemovedNames';[VarNames{:}]']);
        end
        % Returns the variable names
        function VarNames = GetVarNames(self);
            if iscell(self.Conditions(1).Variable);
                for n = 1:size(self.Conditions(1).Variable,1);
                    VarNames{n} = self.Conditions(1).Variable{n,1};
                end
            else
                VarNames = {};
            end
        end
        
        % Produces a dimensional map of the constants
        function ConstDimensionMap(self);
            % Keys are the fieldnames
            Keys = fieldnames(self.Conditions(1).Constant);
            % Loop through each key
            for Parameter = 1:numel(Keys);
                % Get the size
                ParameterSize{Parameter} = size(self.Conditions(1).Constant.(Keys{Parameter}));
                
                % Assign the 'a' or 'd' dimension
                if ParameterSize{Parameter}(1)==1;
                    Dimension1 = {'a'};
                elseif ParameterSize{Parameter}(1)==2;
                    Dimension1 = {'d'};
                elseif any(strcmp(Keys{Parameter},{'Hypsometry','Hypsometric_Bin_Midpoints','Subduction_Rate','Subduction_Gauss'}));
                    Dimension1 = {'s'};
                elseif strcmp(Keys{Parameter},{'Core_Depths'});
                    Dimension1 = {'c'};
                elseif sum(strcmp(Keys{Parameter},{'Outgassing_Gauss'}));
                    Dimension1 = {'g'};
                else
                    Dimension1 = {['k_',num2str(ParameterSize{Parameter}(1))]};
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
            for Parameter = 1:size(self.Conditions(1).Variable,1);
                Dimensions = self.DimensionMap(self.Conditions(1).Variable{Parameter,1}{1});
                Dimensions{2} = 't';
                self.DimensionMap(self.Conditions(1).Variable{Parameter,1}{1}) = Dimensions;
            end
        end
        
        %% Convert the output data to a matrix
        % ### UNUSED
        function MatrifyData(self);
            Length = sum(cellfun('length',self.Data),1);
            TimeMat = NaN(max(Length),1,size(self.Time,2));
            DataMat = NaN(max(Length),numel(self.Conditions.Initial.Conditions),size(self.Data,2));
            
            for Run = 1:size(self.Data,2);
                TimeMat(1:Length(Run),1,Run) = cell2mat(self.Time(:,Run));
                DataMat(1:Length(Run),1:numel(self.Conditions.Initial.Conditions),Run) = cell2mat(self.Data(:,Run));
            end
            self.Time = TimeMat;
            self.Data = DataMat;
        end
        
        function MatrifyData_Par(self,Time,Data);
            for n = 1:numel(Data);
                DataT{n} = vertcat(Data{n}{:});
                TimeT{n} = vertcat(Time{n}{:});
            end
            Length = sum(cellfun('length',DataT),1);
            TimeMat = NaN(max(Length),1,size(Time,2));
            DataMat = NaN(max(Length),size(DataT{1},2),size(Data,2));
            
            for Run = 1:numel(DataT);
                TimeMat(1:Length(Run),1,Run) = cell2mat(TimeT(Run));
                DataMat(1:Length(Run),1:size(DataT{1},2),Run) = cell2mat(DataT(Run));
            end
            self.Time = TimeMat;
            self.Data = DataMat;
        end
        
        %% Save the output data
        % ### UNUSED
        function SaveData_Old(self,Filename);
            Deflate = 5;
            Format = 'netcdf4_classic';
            
            Names = {'Time','Atmosphere.CO2','Algae','Phosphate','DIC','Alkalinity'};
            Time = self.Time;
            Atmosphere.CO2 = self.Data(:,1,:);
            Algae = self.Data(:,2,:);
            Phosphate = self.Data(:,3:4,:);
            DIC = self.Data(:,5:6,:);
            Alkalinity = self.Data(:,7:8,:);
            
            UserInput = ncsave_OO(Filename,Names,Format,Deflate);
            
            ConstNames = fieldnames(self.Conditions.Constant);
            ncadd_OO(self,Filename,ConstNames,Format,Deflate,UserInput);
        end
        
        %% Saving Data
        % ### UNUSED
        function TotalPerts = GetTotalPerts(self,Runs);
            PertNumber = 0;
            for RunIndex = 1:numel(Runs);
                ChunkNumber = numel(Runs(RunIndex).Chunks);
                for ChunkIndex = 1:ChunkNumber;
                    PertNumber = PertNumber+size(Runs(RunIndex).Chunks(ChunkIndex).Perturbations,1);
                end
            end
            TotalPerts = PertNumber;
        end
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
            
            Max_Subduction = self.GetMaxSubduction;
            Dims = {'s',max(Max_Subduction)};
            
            Core_Number = numel(self.Conditions.Constant.Core_Depths);
            Dimc = {'c',Core_Number};
            
            Max_Outgassing = self.GetMaxOutgassing(Runs);
            Dimm = {'m',max(Max_Outgassing)};
            
            Out_Gauss_Elements = self.GetOutgassingGaussElements;
            Dimg = {'g',max(Out_Gauss_Elements)};
            
            % Vertical Data
            netcdf.defDim(FileID,Dima{1},Dima{2});
            netcdf.defDim(FileID,Dimd{1},Dimd{2});
            
            % Constants
            netcdf.defDim(FileID,Dimk{1},Dimk{2});
            netcdf.defDim(FileID,'k_13',13);
 
            % Time
            netcdf.defDim(FileID,Dimt{1},Dimt{2});
            
            % Runs
            netcdf.defDim(FileID,Dimr{1},Dimr{2});
            
            % Outgassing
            netcdf.defDim(FileID,Dimm{1},Dimm{2});
            % Gauss
            netcdf.defDim(FileID,Dimg{1},Dimg{2});
            % Carbonate
            netcdf.defDim(FileID,Dims{1},Dims{2});
            netcdf.defDim(FileID,Dimc{1},Dimc{2});
            
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
            CurrentDims = {'a','t','r'};
            VarID = netcdf.defVar(DataGrpID,'Time','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2}),netcdf.inqDimID(FileID,CurrentDims{3})]);
            netcdf.defVarFill(DataGrpID,VarID,false,NaN);
            
            Indices = {1,2,[3,4],[5,6],[7,8],9,[10,11],12,13,14,15,16};
            for n = 1:numel(Indices);
                if numel(Indices{n})==1;
                    CurrentDims{1} = 'a';
                    VarID = netcdf.defVar(DataGrpID,self.DataNames{n},'double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2}),netcdf.inqDimID(FileID,CurrentDims{3})]);
                else
                    CurrentDims{1} = 'd';
                    VarID = netcdf.defVar(DataGrpID,self.DataNames{n},'double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2}),netcdf.inqDimID(FileID,CurrentDims{3})]);
                end
                netcdf.defVarFill(DataGrpID,VarID,false,NaN);
            end
            
            CurrentDims = {'a','t','r'};
            VarID = netcdf.defVar(DataGrpID,'Lysocline','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,'t'),netcdf.inqDimID(FileID,CurrentDims{3})]);
            netcdf.defVarFill(DataGrpID,VarID,false,NaN);
            
            CurrentDims = {'s','k','r'};
            VarID =  netcdf.defVar(DataGrpID,'Seafloor','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2}),netcdf.inqDimID(FileID,CurrentDims{3})]);
            netcdf.defVarFill(DataGrpID,VarID,false,NaN);
            
            CurrentDims = {'m','k','r'};
            VarID =  netcdf.defVar(DataGrpID,'Outgassing','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2}),netcdf.inqDimID(FileID,CurrentDims{3})]);
            netcdf.defVarFill(DataGrpID,VarID,false,NaN); 
            
            CurrentDims = {'a','t','r'};
            VarID = netcdf.defVar(DataGrpID,'Seafloor_Total','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2}),netcdf.inqDimID(FileID,CurrentDims{3})]);
            netcdf.defVarFill(DataGrpID,VarID,false,NaN);
            
            CurrentDims = {'c','t','r'};
            VarID = netcdf.defVar(DataGrpID,'Cores','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2}),netcdf.inqDimID(FileID,CurrentDims{3})]);
            netcdf.defVarFill(DataGrpID,VarID,false,NaN);
            
            % Variables
            VarNames = self.GetVarNames;
            UniqueVarNames = unique([VarNames{:}]);
            for n = 1:numel(UniqueVarNames);
                CurrentDims = self.DimensionMap(UniqueVarNames{n});
                VarID = netcdf.defVar(VarGrpID,UniqueVarNames{n},'double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,'t'),netcdf.inqDimID(FileID,CurrentDims{3})]);
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
            Count = [1,size(self.Data,2),1];
            Stride = [1,1,1];
            
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            TimeID = netcdf.inqVarID(DataGrpID,'Time');
            
            % Write time to file
            netcdf.putVar(DataGrpID,TimeID,Start,Count,self.Time);
            
            % Loop
            Indices = {1,2,[3,4],[5,6],[7,8],9,[10,11],12,13,14,15,16};
            for n = 1:numel(Indices);
                if numel(Indices{n})==1;
                    Count(1) = 1;
                    netcdf.putVar(DataGrpID,netcdf.inqVarID(DataGrpID,self.DataNames{n}),Start,Count,Stride,self.Data(Indices{n},:));
                else
                    Count(1) = 2;
                    netcdf.putVar(DataGrpID,netcdf.inqVarID(DataGrpID,self.DataNames{n}),Start,Count,Stride,self.Data(Indices{n},:));
                end
            end
            
            Count = [numel(self.Seafloor),1,1];
            netcdf.putVar(DataGrpID,netcdf.inqVarID(DataGrpID,'Seafloor'),Start,Count,Stride,self.Seafloor);
            
            Count = [numel(self.Outgassing),1,1];
            netcdf.putVar(DataGrpID,netcdf.inqVarID(DataGrpID,'Outgassing'),Start,Count,Stride,self.Outgassing);
                    
            Count = [1,numel(self.Seafloor_Total),1];
            netcdf.putVar(DataGrpID,netcdf.inqVarID(DataGrpID,'Seafloor_Total'),Start,Count,Stride,self.Seafloor_Total);
            
            Count = [size(self.Cores,1),size(self.Cores,2),1];
            netcdf.putVar(DataGrpID,netcdf.inqVarID(DataGrpID,'Cores'),Start,Count,Stride,self.Cores);
            
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
            
%             VarGrpID = netcdf.inqNcid(FileID,'Variables');
%             
%             VarNames = self.GetVarNames;
%             UniqueVarNames = unique([VarNames{:}]);
%             for n = 1:numel(UniqueVarNames);
%                 Count = [size(self.Conditions.Constant.(UniqueVarNames{n})),1];
%                 netcdf.putVar(VarGrpID,netcdf.inqVarID(VarGrpID,UniqueVarNames{n}),Start,Count,Stride,self.Conditions.Constant.(UniqueVarNames{n}));
%             end
            
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
                Count = [size(self.Conditions.Constant.(VarNames{n}{1})),1];
                netcdf.putVar(VarGrpID,netcdf.inqVarID(VarGrpID,VarNames{n}{1}),Start,Count,Stride,(self.Conditions.Constant.(VarNames{n}{1})));
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
            Count = [1,size(self.(VarNames{n}),2),1];
                netcdf.putVar(DataGrpID,netcdf.inqVarID(DataGrpID,VarNames{n}),Start,Count,Stride,self.(VarNames{n}));
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