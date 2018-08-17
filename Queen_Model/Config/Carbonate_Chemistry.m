classdef Carbonate_Chemistry < matlab.mixin.Copyable & ParameterLoad
    properties
        Boron
        Silica
        Phosphate
        Fluoride
        Sulphate
        Calcium
        Magnesium
        
        Depths
        Temperature
        Pressure
        Salinity
        
        Pressure_Correction
        CCK_Mg_Ca_Correction
        CCK_Depth_Correction
        Coefficients
        CCKs
        
        k0_Matrix
        k1_Matrix
        k2_Matrix
        kw_Matrix
        kb_Matrix
        ksp_cal_Matrix
        ksp_arag_Matrix
        ks_Matrix
        
        H_In
        DIC
        Alkalinity
        pH
        Saturation_State_C
        CO2
        HCO3
        CO3
        Iteration_Flag = 0;
        Tolerance = [0.0001;0.0001];
        
        Lysocline_In
        Lysocline
        Lysocline_Iteration_Flag = 0;
        Lysocline_Tolerance = 1e-6;
        
        Solver
        Lysocline_Solver
    end
    properties (Hidden=true);
        Model_Directory
        Available_Solvers
        Available_Lysocline_Solvers
        Solver_Handle
        Lysocline_Solver_Handle
    end
    methods
        function self = Carbonate_Chemistry(Empty_Cell_Flag,Midpoints);            
            Model_Filepath = which('GUI.m');
            Model_Dir = Model_Filepath(1:end-12);
            self.Model_Directory = Model_Dir;            
            
            self.SetAvailableSolvers();
            % Set default core as Core
            self = self.SetSolver("Carbonate_Chemistry_Solver");
            
            self.SetAvailableLysoclineSolvers();
            % Set default solver
            self = self.SetLysoclineSolver("Lysocline_Solver_Regula_Falsi");
            
            if nargin==0 || ~Empty_Cell_Flag;
                self = DefineCarbonateChemistryParameters(self,Midpoints);            
            elseif Empty_Cell_Flag
                Properties = properties(self);
                for Property_Index = 1:numel(Properties);
                    self.(Properties{Property_Index}) = {};
                end
            end
        end
        function SetCoefficients(self);
            self.Coefficients = GetCoefficients(self);
        end
        function SetCCKs(self);
             [self.CCKs,self.CCK_Depth_Correction] = GetCCKs(self.Salinity,self.Temperature,self.Pressure,self.Pressure_Correction,self.Coefficients);
        end
        function Solve(self,Initial_pH,Iteration_Flag,Tolerance);
            if nargin<2 || isempty(Initial_pH);
                if ~isempty(self.pH);
                    if numel(self.pH)==2;
                        Initial_pH = self.pH;
                    elseif numel(self.pH)==1;
                        Initial_pH = [self.pH;self.pH];
                    end
                else
                    Initial_pH = [8;8];
                end
            end
            Initial_H = (10.^(-Initial_pH))*1000;
            if nargin<3;
                Iteration_Flag = 0;
            end
            if nargin<4;
                Tolerance = [0.0001;0.0001];
            end
            [self.pH,self.CO2,~,~,self.Saturation_State_C,~] = Carbonate_Chemistry_Solver(self.DIC,self.Alkalinity,{self.Boron,self.Silica,NaN,self.Calcium,self.Phosphate},Initial_H,self.CCKs,Iteration_Flag,Tolerance);
        end
        function Solve_Lysocline(self,Initial_Lysocline,Iteration_Flag,Tolerance);
            if nargin<2 || isempty(Initial_Lysocline);
                if ~isempty(self.Lysocline);
                    Initial_Lysocline = self.Lysocline;
                else
                    Initial_Lysocline = [0;10000];
                end
            end
            if nargin<3;
                Iteration_Flag = 0;
            end
            if nargin<4;
                Tolerance = 1e-6;
            end
            self.Lysocline = Lysocline_Solver_Regula_Falsi(self.DIC(2),self.Depths,self.Temperature,self.Salinity,self.pH,self.Calcium,self.Coefficients,Initial_Lysocline,Iteration_Flag,Tolerance);
        end        
        function Available_Solvers = GetAvailableSolvers(self,src,event);
            % Looks for directory contents matching pattern
            AvailableSolversStruct = dir([self.Model_Directory,'/Functions/Carbonate_Chemistry/pH/Carbonate_Chemistry_Solver*.m']);
            Available_Solvers = strings(size(AvailableSolversStruct,1),1);
            
            for SolverIndex = 1:numel(Available_Solvers);
                Available_Solvers(SolverIndex) = strrep(string(AvailableSolversStruct(SolverIndex).name),".m","");
            end
        end
        function SetAvailableSolvers(self);
            self.Available_Solvers = self.GetAvailableSolvers();
        end
        function Available_Lysocline_Solvers = GetAvailableLysoclineSolvers(self,src,event);
            % Looks for directory contents matching pattern
            AvailableSolversStruct = dir([self.Model_Directory,'/Functions/Carbonate_Chemistry/Lysocline/Lysocline_Solver*.m']);
            Available_Lysocline_Solvers = strings(size(AvailableSolversStruct,1),1);
            
            for SolverIndex = 1:numel(Available_Lysocline_Solvers);
                Available_Lysocline_Solvers(SolverIndex) = strrep(string(AvailableSolversStruct(SolverIndex).name),".m","");
            end
        end
        function SetAvailableLysoclineSolvers(self);
            self.Available_Lysocline_Solvers = self.GetAvailableLysoclineSolvers();
        end
        function self = SetSolver(self,Solver);
            if ~isstring(Solver);
                Solver = string(Solver);
            end
            if any(self.Available_Solvers==Solver);
                self.Solver = Solver;
            end
        end
        function self = SetLysoclineSolver(self,Lysocline_Solver);
            if ~isstring(Lysocline_Solver);
                Lysocline_Solver = string(Lysocline_Solver);
            end
            if any(self.Available_Lysocline_Solvers==Lysocline_Solver);
                self.Lysocline_Solver = Lysocline_Solver;
            end
        end
        function SolverToHandle(self);
            self.Solver_Handle = str2func(self.Solver);
        end
        function LysoclineSolverToHandle(self);
            self.Lysocline_Solver_Handle = str2func(self.Lysocline_Solver);
        end
    end
end