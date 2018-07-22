classdef Functional < matlab.mixin.Copyable
    properties
        Solver
        Core
    end
    properties (Hidden=true)
        ModelDirectory
        AvailableCores
        AvailableSolvers
    end
    methods
        function self = Functional();
            Model_Filepath = which('GUI.m');
            Model_Dir = Model_Filepath(1:end-12);
            self.ModelDirectory = Model_Dir;
            
            self.SetAvailableCores();
            % Set default core as Core
            self = self.SetCore('Core');
            
            self.SetAvailableSolvers();
            % Set default solver
            self = self.SetSolver('Heun_Unoptimised');
            if isempty(self.Solver) || strcmp(self.Solver,"");
                self = self.SetSolver(self.AvailableSolvers{1});
            end
        end
         %% Gets available cores
        function AvailableCores = GetAvailableCores(self,src,event);
            % Once an option has been selected
            % Looks for directory contents matching pattern
            AvailableCoresStruct = dir([self.ModelDirectory,'Core/**/*.m']);
            AvailableCores = strings(size(AvailableCoresStruct,1),1);
            for CoreIndex = 1:numel(AvailableCores);
                AvailableCores(CoreIndex) = strrep(string(AvailableCoresStruct(CoreIndex).name),".m","");
            end
        end
        function SetAvailableCores(self);
            self.AvailableCores = self.GetAvailableCores();
        end
        function self = SetCore(self,Core);
            if ~isstring(Core);
                Core = string(Core);
            end
            if any(self.AvailableCores==Core);
                self.Core = Core;
            end
        end
        %% Gets available solvers
        function AvailableSolvers = GetAvailableSolvers(self,src,event);
            % Looks for directory contents matching pattern
            AvailableSolversStruct = dir([self.ModelDirectory,'Functions\Solvers\*.m']);
            AvailableSolvers = strings(size(AvailableSolversStruct,1),1);
            
            for SolverIndex = 1:numel(AvailableSolvers);
                AvailableSolvers(SolverIndex) = strrep(string(AvailableSolversStruct(SolverIndex).name),".m","");
            end
        end
        function SetAvailableSolvers(self);
            self.AvailableSolvers = self.GetAvailableSolvers();
        end
        function self = SetSolver(self,Solver);
            if ~isstring(Solver);
                Solver = string(Solver);
            end
            if any(self.AvailableSolvers==Solver);
                self.Solver = Solver;
            else
                warning("Solver not set correctly");
            end            
        end
        
        %% Load
        function Retrieved_Data = LoadIndividual(self,Filename,Individual,Indices);
            
            if ~ischar(Individual);
                Individual = char(Individual);
            end
            
            FileID = netcdf.open(Filename,'NOWRITE');
            FuncGrpID = netcdf.inqNcid(FileID,'Functionals');
            VarID = netcdf.inqVarID(FuncGrpID,Individual);
            
            [~,~,DimIDs,~] = netcdf.inqVar(FuncGrpID,VarID);
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
            
            Retrieved_Data = netcdf.getVar(FuncGrpID,VarID,Start,Count);
            Retrieved_Data = string(Retrieved_Data(double(Retrieved_Data)~=0));
            netcdf.close(FileID);
        end
        function Load(self,Filename);
            self.Core = self.LoadIndividual(Filename,"Core");
            self.Solver = self.LoadIndividual(Filename,"Solver");
        end
    end
end