classdef GUI < handle;
    properties
        Handle
        Size
        Gecco
    end
    properties (Hidden=true);
        % Tabs
        TabGroupHandle
        SplashTabHandle
        RunTabHandles
        PlotTabHandle
        BoxSize
        ButtonMargin
        ButtonSpacing = [0.09,0.099];
        ButtonThinSpacing = [0,0.045];
        ButtonAddRmSize = [0.0225,0.045];
        ButtonSize = [0.07,0.04];
        TextBoxSpacing = [0,-0.05,0,0];
        DropDownSize = [0.11,0.0874];
        DropDownHorzSpacing = 0.12;
        % Run Components
        RunTable
        RunTableUI
        RunMatrix
        % Condition Components
        CondTypeSelectorUI
        CondGroupSelectorUI
        CondSelectorUI
        CondTableUI
        % Initial Components
        InitMatrix
        % Constant Components
        ConstMatrix
        % PertTrans
        PertTransTableUI
        ChangeSelectorUI
        % Perturbation Components
        PertMatrix = {cell(0,7)};
        % Variable Components
%         TransTableUI
        TransMatrix = {cell(0,5)};
        % Log Components
        LogMessages = cell(1);
        LogBoxUI
        % Current Selections
        RunIndices
        TransIndices
        SelectedRun = 1;
        SelectedRegion = 1;
        SelectedChunk
        SelectedPert
        SelectedTab = 1;
        PlotRunSelectorUI = 1;
        RunSelectorLabelUI
        RunSelectorUI
        RegionSelectorLabelUI
        RegionSelectorUI
        % Dealing With Files
        InputFileUI
        OutputFilepathUI
        OutputFilenameUI
        FilenameWarningUI
        % Splash Files
        SplashOutputFilepathUI
        SplashOutputFilenameUI
        SplashInputFileUI
        SplashFilenameWarningUI
        SplashSaveByRunsTickboxUI
        SplashSaveByRegionsTickboxUI
        SplashSaveToSameFileTickboxUI
        SplashShouldSaveTickboxUI
        % Flags
        ValidatedFlag = 0;
%         SaveToSameFileFlag = 1;
%         SaveToRunFilesFlag = 0;
%         SaveToRegionFilesFlag = 0;        
        % Plots
        s
        Colours
        ColourBox
        SubplotIndex = 1;
        % Logo
        Logo
    end
    methods
        function self = GUI(FileInput);
            Model_Filepath = which('GUI.m');
            Model_Dir = Model_Filepath(1:end-12);
            self.Logo = imread(char(strcat(Model_Dir,"/Resources/Logo.png")));
%             CurrentDir = dir('.');
%             CurrentDirRight = sum(strcmp(vertcat({CurrentDir(:).name}),'GECCOGUI.m'));
            if isempty(Model_Filepath);
                error('Model not found, add to path');
            end
            
            Split_Dir = strsplit((Model_Dir),'\');
            disp([Split_Dir{7},' GUI instantiated']);
            
            self.Gecco = GECCO;
            
            if nargin==0;
                FileInput = 'none';
            end
            
            Temp = load('Colours.mat');
            self.Colours = Temp.Colours;
            
            self.BoxSize{1} = [0.38,0.175];
            self.BoxSize{2} = [0.4,0.175];
            self.ButtonMargin{1} = 0.0173;
            
            self.Handle = figure('Position',[100,100,1100,600]); 
            self.Size = get(self.Handle,'Position');
            addpath([Model_Dir,'Functions\Solvers\']);
            
            %% Tabbing
            self.TabGroupHandle = uitabgroup('Parent',self.Handle,...
                                             'SelectionChangedFcn',@self.TabChangeCallback,...
                                             'Tag','TabChange');
            self.SplashTabHandle = uitab('Parent',self.TabGroupHandle,'Title','Splash');
            self.RunTabHandles = {uitab('Parent',self.TabGroupHandle,'Title','Run 1'),uitab('Parent',self.TabGroupHandle,'Title','+')};
            self.PlotTabHandle = uitab('Parent',self.TabGroupHandle,'Title','Plot Data');

            self.RunTableUI.Data = self.BuildChunkTable();
%             self.ConstTableUI.Data = [];
                
            self.TabChangeCallback();

            %% Plot Control
            self.PlotRunSelectorUI = uicontrol('Style','popupmenu',...
                                               'Units','Normalized',...
                                               'Position',[0.0173,0.9423,0.1369,0.035],...
                                               'String','-',...
                                               'Parent',self.PlotTabHandle,...
                                               'Callback',@self.SelectPlot);
            PlotsRightArrowUI = uicontrol('Style','pushbutton',...
                                          'Units','Normalized',....
                                          'Position',[0.95,0.5,0.035,0.15],...
                                          'String','>',...
                                          'Parent',self.PlotTabHandle,...
                                          'Callback',@self.PlotRight);
            PlotsLeftArrowUI = uicontrol('Style','pushbutton',...
                                         'Units','Normalized',....
                                         'Position',[0.02,0.5,0.035,0.15],...
                                         'String','<',...
                                         'Parent',self.PlotTabHandle,...
                                         'Callback',@self.PlotLeft);

            self.s{1} = subplot(5,1,1,'Parent',self.PlotTabHandle);
            self.s{2} = subplot(5,1,2,'Parent',self.PlotTabHandle);
            self.s{3} = subplot(5,1,3,'Parent',self.PlotTabHandle);
            self.s{4} = subplot(5,1,4,'Parent',self.PlotTabHandle);
            self.s{5} = subplot(5,1,5,'Parent',self.PlotTabHandle);


            %% Input
            if ~strcmp(FileInput,'none') && ~strcmp(FileInput,'-headless');
                self.FullCopy(FileInput);
            end
        end
        
        %% Filepath Callbacks
        % Open browse window for filepath
        function SetOutputFilepath(self,src,event);
            if isempty(self.OutputFilepathUI.String);
                OutputFilepath = uigetdir('./../../../Results');
            else
                OutputFilepath = uigetdir(self.OutputFilepathUI.String);
            end
            if OutputFilepath~=0;
                self.OutputFilepathUI.String = OutputFilepath;
                self.Gecco.Information.Output_Filepath = OutputFilepath;
            end
        end
        % Reads in a file and sets the attributes
        function Input_File = GetInputFile(self,src,event);
            if strcmp(self.SplashInputFileUI.String,"Input File");
                [InputFilename,InputFilepath] = uigetfile('*.nc','DefaultName','./../../../Results/');
            else
                SplitSearchFilepath = string(strsplit(self.SplashInputFileUI.String,'\'));
                SearchFilepath = strjoin(SplitSearchFilepath(1:end-1),'\');
                [InputFilename,InputFilepath] = uigetfile('*.nc','DefaultName',char(SearchFilepath));
            end
            if InputFilename~=0;
                Input_File = [InputFilepath,InputFilename];
            else
                Input_File = 0;
            end
        end
        function SetInputFile(self,src,event);
            if InputFilename~=0;
                self.Gecco.Information.Input_File = [InputFilepath,InputFilename];
                self.InputFileUI.String = self.Gecco.Information.Input_File;
            end
        end
        function SetOutputFileCallback(self,src,event);
            self.ValidateFilename(src,event);
            self.SetOutputFilename(src,event);
            self.CheckFileExists(src,event);
        end
        % Check file exists and produce relevant output
        function CheckFileExists(self,src,event);
            if ~isempty(self.OutputFilepathUI.String);
%                 FullFile = [self.OutputFilepathUI.String,'\',self.OutputFilenameUI.String];
%                 Exists = exist(FullFile,'file');
            self.Gecco.CheckFileExists();
                if self.Gecco.FileExists;
                    set(self.FilenameWarningUI,'String','File exists',...
                                               'ForegroundColor','red');
                else
                    set(self.FilenameWarningUI,'String','Go on',...
                                               'ForegroundColor','green');
                end
            end
        end
        
        function OutputFilename = CheckFilenameEndNC(self,Filename);
            SplitFilename = strsplit(Filename,'.');
            if numel(SplitFilename)==1;
                OutputFilename = strcat(Filename,'.nc');
%                 self.UpdateLogBox("Warning: File extension .nc added");
            else
                Ending = SplitFilename{end};
                if ~strcmp(Ending,'nc');
                    OutputFilename = strcat(SplitFilename{1:end-1},'.nc');
%                     self.UpdateLogBox("Warning: File extension changed to .nc");
                else
                    OutputFilename = Filename;
                end
            end
        end
        function SetOutputFilename(self,src,event);
            self.Gecco.Information.Output_Filename = src.String;
        end
        
        
        function File = GetFilepath(self,src,event);
            if strcmp(src.Tag,"SplashInputFileBrowseButton") || strcmp(src.Tag,"RunLoadButton");
                File = self.GetInputFile();                
            elseif isempty(self.SplashOutputFilepathUI.String);
                File = uigetdir('./../../../Results');
            else
                File = uigetdir(self.SplashOutputFilepathUI.String);
            end
        end
        function OutputFilepath = ValidateFilepath(self,Filepath);
            if Filepath == 0;
                OutputFilepath = "";
            elseif ischar(Filepath);
                OutputFilepath = string(Filepath);
            else
                OutputFilepath = Filepath;
            end
        end
        function SetFilepath(self,src,event,Filepath);
            if nargin<4;
                ValidFilepath = self.ValidateFilepath(src.String);
            else
                ValidFilepath = self.ValidateFilepath(Filepath);
            end
            
            if strcmp(src.Tag,"SplashInputFileBrowseButton") || strcmp(src.Tag,"SplashInputFilename") || strcmp(src.Tag,"RunLoadButton");
                if ~strcmp(ValidFilepath,"");
                    ValidFilepathWithNC = self.CheckFilenameEndNC(ValidFilepath);
                    self.SplashInputFileUI.String = ValidFilepathWithNC;
                    self.Gecco.Information.Input_File = ValidFilepathWithNC;
                    self.SplashInputFileUI.ForegroundColor = self.Colours.black;
                elseif strcmp(src.String,"");
                    self.SelectiveClear(src,event);
                else
                    % Do nothing
                end
            elseif strcmp(src.Tag,"SplashOutputFilepathBrowseButton") || strcmp(src.Tag,"SplashOutputFilepath");
                if ~strcmp(ValidFilepath,"");
                    self.SplashOutputFilepathUI.String = ValidFilepath;
                    self.Gecco.Information.Output_Filepath = ValidFilepath;
                    self.SplashOutputFilepathUI.ForegroundColor = self.Colours.black;
                elseif strcmp(src.String,"");
                    self.SelectiveClear(src,event);                
                else
                    % Do nothing
                end
            elseif strcmp(src.Tag,"SplashOutputFilename");
                if ~strcmp(ValidFilepath,"");
                    ValidFilepathWithNC = self.CheckFilenameEndNC(ValidFilepath);
                    self.SplashOutputFilenameUI.String = ValidFilepathWithNC;
                    self.Gecco.Information.Output_Filename = ValidFilepathWithNC;
                    self.SplashOutputFilenameUI.ForegroundColor = self.Colours.black;
                elseif strcmp(src.String,"");
                    self.SelectiveClear(src,event);                
                else
                    % Do nothing
                end
            elseif strcmp(src.Tag,"InputFileBrowseButton") || strcmp(src.Tag,"InputFile");
                if ~strcmp(ValidFilepath,"");
                    ValidFilepathWithNC = self.CheckFilenameEndNC(ValidFilepath);
                    self.InputFileUI.String = ValidFilepathWithNC;
                    self.Gecco.Runs(self.SelectedRun).Information.InputFile = ValidFilepathWithNC;
                    self.InputFileUI.ForegroundColor = self.Colours.black;
                elseif strcmp(src.String,"");
                    self.SelectiveClear(src,event);                
                else
                    % Do nothing
                end
            elseif strcmp(src.Tag,"OutputFilepathBrowseButton") || strcmp(src.Tag,"OutputFilepath");
                if ~strcmp(ValidFilepath,"");
                    ValidFilepathWithNC = self.CheckFilenameEndNC(ValidFilepath);
                    self.OutputFilepathUI.String = ValidFilepathWithNC;
                    self.Gecco.Runs(self.SelectedRun).Information.OutputFilepath = ValidFilepathWithNC;
                    self.OutputFilepathUI.ForegroundColor = self.Colours.black;
                elseif strcmp(src.String,"");
                    self.SelectiveClear(src,event);
                else
                    % Do nothing
                end
            elseif strcmp(src.Tag,"OutputFilename");
                if ~strcmp(ValidFilepath,"");
                    ValidFilepathWithNC = self.CheckFilenameEndNC(ValidFilepath);
                    self.OutputFilenameUI.String = ValidFilepathWithNC;
                    self.Gecco.Runs(self.SelectedRun).Information.Output_Filename = ValidFilepathWithNC;
                    self.OutputFilenameUI.ForegroundColor = self.Colours.black;
                elseif strcmp(src.String,"");
                    self.SelectiveClear(src,event);
                else
                    % Do nothing
                end
            else
                
            end
        end
        function SetSplashPaths(self);
            if strcmp(self.Gecco.Information.Input_File,"") || isempty(self.Gecco.Information.Input_File);
                self.SplashInputFileUI.String = "Input File";
            else
                self.SplashInputFileUI.String = self.Gecco.Information.Input_File;
                self.SplashInputFileUI.Enable = "On";
                self.SplashInputFileUI.ForegroundColor = self.Colours.black;
            end
            
            if strcmp(self.Gecco.Information.Output_Filepath,"") || isempty(self.Gecco.Information.Output_Filepath);
                self.SplashOutputFilepathUI.String = "Output Filepath";
            else
                self.SplashOutputFilepathUI.String = self.Gecco.Information.Output_Filepath;
                self.SplashOutputFilepathUI.Enable = "On";
                self.SplashOutputFilepathUI.ForegroundColor = self.Colours.black;
            end
            
            if strcmp(self.Gecco.Information.Output_Filename,"") || isempty(self.Gecco.Information.Output_Filename);
                self.SplashOutputFilenameUI.String = "Output Filename";
            else
                self.SplashOutputFilenameUI.String = self.Gecco.Information.Output_Filename;
                self.SplashOutputFilenameUI.Enable = "On";
                self.SplashOutputFilenameUI.ForegroundColor = self.Colours.black;
            end
        end
        function GetAndSetFilepath(self,src,event);
            File = self.GetFilepath(src,event);
            self.SetFilepath(src,event,File);
        end
        
        
        %% Model Callbacks
        % Changes path to correct model
        function ChangeModelCallback(self,src,event);
           self.RemoveModelFromPath(src,event);
           self.AddModelToPath(src,event);
           self.GetAvailableCores(src,event);
        end
        % Gets available models
        function GetInstalledModels(self,src,event);
            % Looks for directory contents matching pattern
            DirectoryContentsModelsFull = dir([self.ModelDirectory,'..\*_Model*']);
            % Concatenates the names from the struct
            self.InstalledModels = vertcat({'-',DirectoryContentsModelsFull(:).name});
            % Sets the appropriate string
            src.String = self.InstalledModels;
        end
        % Gets available cores
        function GetAvailableCores(self,src,event);
            % Once an option has been selected
            if ~isempty(self.CoreUI);
                % Looks for directory contents matching pattern
                AvailableCoresFull = dir([self.ModelDirectory,'Core\**\*.m']);
                % Concatenates the names from the struct
                self.AvailableCores = strrep(vertcat({AvailableCoresFull(:).name}),'.m','');
                % Sets the appropriate string
                self.CoreUI.String = self.AvailableCores;
            end
        end
        function SelectCoreCallback(self,src,event);
            self.Gecco.Regions.Core = self.CoreUI.String{self.CoreUI.Value};
            self.Gecco.Regions.CoreFcn = strrep(self.CoreUI.String{self.CoreUI.Value},'.m','');
        end
        function SelectSolverCallback(self,src,event);
            self.Gecco.Regions.Solver = self.SolverUI.String{self.SolverUI.Value};
            self.Gecco.Regions.SolverFcn = str2func(self.SolverUI.String{self.SolverUI.Value});
        end
        
        %% Run Table Callbacks
        function AddRunCallback(self,src,event);
        % Add a run
            self.Gecco.AddRun();
            self.LogMessages = [self.LogMessages,cell(1)];
            self.PertMatrix{end+1} = cell(0,7);
            self.TransMatrix{end+1} = cell(0,5);
            if nargin>1;
                self.RebuildTable(src,event);
            else
                self.RebuildTable();
            end
        end
        function AddChunkCallback(self,src,event);
            % Add a chunk
            % Call the inherent method
            self.Gecco.Runs(self.SelectedRun).AddChunk();
            % Rebuild the table
            self.RebuildTable(src,event);
        end
        function RemoveChunkCallback(self,src,event);
        % Remove an entry from the run table
            % If something is selected
            if ~isempty(self.ChunkIndices);
                % Remove from GECCO
                self.Gecco.Runs(self.SelectedRun).Chunks(self.SelectedChunk) = [];                
                % Rebuild the table
                self.RebuildTable(src,event);
            else
                % Print to log
                self.UpdateLogBox("Error removing run");         
            end
        end        
        function ChunkTableEditCallback(self,src,event);
            self.Gecco.Runs(self.SelectedRun).Chunks(self.SelectedChunk).Time_In = event.Source.Data(event.Indices(1),1:3);
            self.Gecco.Runs(self.SelectedRun).Chunks(self.SelectedChunk).Time_Out = event.Source.Data(event.Indices(1),4:6);
        end
        
        function UpdateCurrentChunk(self,src,event);
        % Store currently selected chunk
            if ~isempty(event.Indices);
                self.SelectedChunk = event.Indices(1);
            end
        end 
        function UpdateRunIndices(self,src,event);
        % Store currently selected indices
            self.UpdateCurrentChunk(src,event);
            self.RunIndices = event.Indices;
        end
        function Chunk_Table = BuildChunkTable(self,src,event);
            for Chunk_Index = 1:numel(self.Gecco.Runs(self.SelectedRun).Chunks);;
                Chunk_Table(Chunk_Index,1:3) = self.Gecco.Runs(self.SelectedRun).Chunks(Chunk_Index).Time_In;
                Chunk_Table(Chunk_Index,4:6) = self.Gecco.Runs(self.SelectedRun).Chunks(Chunk_Index).Time_Out;
            end
        end
        function RebuildTable(self,src,event);
            % Then build the table from scratch
%                 self.RunTableUI.Data = self.BuildRunTable();
                self.RunTableUI.Data = self.BuildChunkTable();
                if nargin>1;
                    self.UpdatePertTransTable(src,event);
                end
%                 if ~strcmp(src.Tag,"TabChange");
%                 end
                % Update the perturbation table data
%                 self.UpdatePertTableDefinition(src,event);
                % Update the variable table data
%                 self.UpdateTransientTable(src,event);
                % Update the initial table titles
%                 self.ExtendInitTableTitles(src,event);
                % Update the constant table titles
%                 self.ExtendConstTableTitles(src,event);
                
                PlotStrings = num2str(1:numel(self.Gecco.Runs));
                PlotCells = strsplit(PlotStrings,' ');
                self.PlotRunSelectorUI.String = PlotCells;
                % Instantiates constant names
%                 self.UpdateConstSelector();
%                 self.ConstSelectorUI.String = self.GetOrderedConstNames();
        end
        
        function LoadRuns(self,src,event);
            if isempty(self.SplashInputFileUI.String) || strcmp(self.SplashInputFileUI.String,"Input File");
                self.GetAndSetFilepath(src,event);
            end
            Chunk_Matrix = ncread(self.SplashInputFileUI.String,'/Replication/Run_Matrix');
            Time_In = Chunk_Matrix(1,1:3);
            Time_Out = Chunk_Matrix(1,4:6);
            self.Gecco.Runs.Chunks(1) = Chunk(Time_In,Time_Out);
            for Chunk_Index = 2:size(Chunk_Matrix,1);
                Time_In = Chunk_Matrix(Chunk_Index,1:3);
                Time_Out = Chunk_Matrix(Chunk_Index,4:6);
                self.Gecco.Runs(self.SelectedRun).AddChunk(Chunk(Time_In,Time_Out));
            end
            self.RunTableUI.Data = Chunk_Matrix;
        end
        
        %% Condition Callbacks
        function CondTableData = GetCondTableData(self);
            if isempty(self.CondSelectorUI.String);
                CondTableData = [];
            else
                self.CondTableUI.ColumnFormat = [];
                if strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Initials');
                    CondTableData = self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Initials.(self.CondSelectorUI.String{self.CondSelectorUI.Value});
                elseif strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Constants');
                    if strcmp(self.CondGroupSelectorUI.String{self.CondGroupSelectorUI.Value},'Carbonate_Chemistry');
                        if strcmp(self.CondSelectorUI.String{self.CondSelectorUI.Value},'Solver');
                            CondTableData = cellstr(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Constants.Carbonate_Chemistry.Available_Solvers)';
                        elseif strcmp(self.CondSelectorUI.String{self.CondSelectorUI.Value},'Lysocline_Solver');
                            CondTableData = cellstr(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Constants.Carbonate_Chemistry.Available_Lysocline_Solvers)';
                        else
                            CondTableData = self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Constants.(self.CondGroupSelectorUI.String{self.CondGroupSelectorUI.Value}).(self.CondSelectorUI.String{self.CondSelectorUI.Value});
                        end
                        self.CondTableUI.ColumnFormat = {CondTableData};
                    else
                        CondTableData = self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Constants.(self.CondGroupSelectorUI.String{self.CondGroupSelectorUI.Value}).(self.CondSelectorUI.String{self.CondSelectorUI.Value});
                    end
                elseif strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Functionals');
                    if strcmp(self.CondSelectorUI.String{self.CondSelectorUI.Value},'Core');
                        CondTableData = cellstr(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Functionals.AvailableCores)';
                    elseif strcmp(self.CondSelectorUI.String{self.CondSelectorUI.Value},'Solver');
                        CondTableData = cellstr(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Functionals.AvailableSolvers)';
                    end
                    self.CondTableUI.ColumnFormat = {CondTableData};
                end
            end
        end
        function UpdateCondGroupSelector(self,src,event);
            if strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Initials');
                self.CondGroupSelectorUI.String = {'-'};
                self.CondGroupSelectorUI.Value = 1;
                self.UpdateCondSelector();
            elseif strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Constants');
                self.CondGroupSelectorUI.String = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Constants);
            elseif strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Functionals');
                %                 self.CondGroupSelectorUI.String = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Functionals);
                self.CondGroupSelectorUI.String = {'-'};
                self.CondGroupSelectorUI.Value = 1;
                self.UpdateCondSelector();
            end
        end
        function UpdateCondSelector(self,src,event);
            if strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Initials');
                self.CondSelectorUI.String = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Initials);
            elseif strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Constants');
                self.CondSelectorUI.String = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Constants.(self.CondGroupSelectorUI.String{self.CondGroupSelectorUI.Value}));
            elseif strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Functionals');
                self.CondSelectorUI.String = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Functionals);
            end
            self.CondSelectorUI.Value = 1;
            self.UpdateCondTable();
        end
        function UpdateCondTable(self,src,event);
            if strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Functionals')
                self.GetCondTableData();
                if strcmp(self.CondSelectorUI.String{self.CondSelectorUI.Value},'Core');
                    self.CondTableUI.Data = {char(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Functionals.Core)};
                elseif strcmp(self.CondSelectorUI.String{self.CondSelectorUI.Value},'Solver');
                    self.CondTableUI.Data = {char(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Functionals.Solver)};
                end
            elseif (strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Constants') && strcmp(self.CondGroupSelectorUI.String{self.CondGroupSelectorUI.Value},'Carbonate_Chemistry') && (strcmp(self.CondSelectorUI.String{self.CondSelectorUI.Value},'Solve_Function')||strcmp(self.CondSelectorUI.String{self.CondSelectorUI.Value},'Lysocline_Solve_Function')));
                self.CondTableUI.Data = {char(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Constants.Carbonate_Chemistry.Solve_Function)};
            else
                self.CondTableUI.Data = self.GetCondTableData();
            end
        end
        function CondTableEditCallback(self,src,event);
            if strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Initials');
                self.Gecco.Runs(event.Indices(2)).Regions(1).Conditions.Initials.(self.CondSelectorUI.String{self.CondSelectorUI.Value})(event.Indices(1),1) = event.NewData;
                self.Gecco.Runs(event.Indices(2)).Regions(1).Conditions.Initials.Undeal();
            elseif strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Constants');
                Group = self.CondGroupSelectorUI.String{self.CondGroupSelectorUI.Value};
                Parameter = self.CondSelectorUI.String{self.CondSelectorUI.Value};                
                self.Gecco.Runs(event.Indices(2)).Regions(1).Conditions.Constants.(Group).(Parameter)(event.Indices(1),1) = event.NewData; 
            elseif strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},'Functionals');
                self.Gecco.Runs(event.Indices(2)).Regions(1).Conditions.Functionals.(self.CondSelectorUI.String{self.CondSelectorUI.Value}) = string(event.EditData);
                src.Data = {event.EditData};
            end
        end
        function LoadCondType(self,src,event);
            File = self.Gecco.Information.Input_File;
            if ~strcmp(File,"");
                self.Gecco.Runs(self.SelectedRun).Regions.Conditions.(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value}).Load(File);
            else
                self.UpdateLogBox("File input is empty");
            end
        end
        function LoadCondGroup(self,src,event);
            File = self.Gecco.Information.Input_File;
            if ~strcmp(File,"");
                if strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},"Initials") || strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},"Functionals");
                    self.Gecco.Runs(self.SelectedRun).Regions.Conditions.(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value}).Load(File);
                    self.UpdateLogBox(strcat(string(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value})," has no group, loading the whole type"));
                elseif strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},"Constants");
                    self.Gecco.Runs(self.SelectedRun).Regions.Conditions.(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value}).(self.CondGroupSelectorUI.String{self.CondGroupSelectorUI.Value}).Load(File);               
                    self.UpdateLogBox(strcat(string(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value})," successfully loaded"));
                else
                    self.UpdateLogBox("Condition type is not valid");
                end
            else
                self.UpdateLogBox("File input is empty");
            end
        end
        function LoadCond(self,src,event);
            File = self.Gecco.Information.Input_File;
            if ~strcmp(File,"");
                if strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},"Initials") || strcmp(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value},"Functionals");
                    self.Gecco.Runs(self.SelectedRun).Regions.Conditions.(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value}).LoadIndividual(File,self.CondSelectorUI.String{self.CondSelectorUI.Value});
                    self.UpdateLogBox(strcat(string(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value}),".",string(self.CondSelectorUI.String{self.CondSelectorUI.Value})," successfully loaded"));
                end
            else
                self.UpdateLogBox("File input is empty");
            end
        end
        function LoadCondFinal(self,src,event);
            File = self.Gecco.Information.Input_File;
            if ~strcmp(File,"");
                self.Gecco.Runs(self.SelectedRun).Regions.Conditions.(self.CondTypeSelectorUI.String{self.CondTypeSelectorUI.Value}).LoadFinal(File);
            else
                self.UpdateLogBox("File input is empty");
            end
        end

        %% Initial Callbacks
        % Updates the constant table definition
        function UpdateInitialTable(self,src,event);
            % On cell change update the 
            Table = horzcat(self.Gecco.Runs(1).Regions(1).Conditions.Initials(1:end).(src.String{src.Value}));
            self.InitialTableUI.Data = Table;
        end
        function InitTableEditCallback(self,src,event);
            self.Gecco.Runs(1).Regions(1).Conditions.Initials(event.Indices(2)).(self.InitSelectorUI.String{self.InitSelectorUI.Value})(event.Indices(1),1) = event.NewData;
            self.Gecco.Runs(1).Regions(1).Conditions.Initials.Undeal();
        end
        function ExtendInitTableTitles(self,src,event);
            Chunk_Number = numel(self.Gecco.Runs(self.SelectedRun).Chunks);
            for Chunk_Index = 1:Chunk_Number;
                CellTitle{Chunk_Index} = ['Chunk ',num2str(Chunk_Index)];
            end
            self.InitialTableUI.ColumnName = CellTitle;
        end
        function LoadInits(self,src,event);
            if isempty(self.Gecco);
                self.UpdateLogBox("Please instantiate model first");
            elseif isempty(self.RunTableUI.Data);
                self.UpdateLogBox("No runs to load");
            else
                if isempty(self.InputFileUI.String);
                    self.SetInputFilepath;
                end
                InitMatrix = ncread(self.InputFileUI.String,'/Replication/Initial_Matrix');
                try
                    OutMatrix = ncread(self.InputFileUI.String,'/Replication/Initial_Outgassing');
                catch
                    OutMatrix = ncread(self.InputFileUI.String,'/Replication/Initial_Metamorphism');
                end
                if size(InitMatrix,2)<size(self.RunTableUI.Data,1);
                    self.UpdateLogBox("More runs than initial conditions");
                    for Run_Index = 1:size(self.InitMatrix,1);
                        self.Gecco.Runs(1).Regions(1).Conditions(Run_Index).Initial.Conditions = InitMatrix(:,Run_Index);
                        self.Gecco.Runs(1).Regions(1).Conditions(Run_Index).Deal;
                        
                        self.Gecco.Runs(1).Regions(1).Conditions(Run_Index).Initial.Outgassing = OutMatrix(:,Run_Index);
                    end 
                elseif size(InitMatrix,2)==size(self.RunTableUI.Data,1);
                    for Run_Index = 1:size(self.RunTableUI.Data,1);
                        self.Gecco.Runs(1).Regions(1).Conditions(Run_Index).Initial.Conditions = InitMatrix(:,Run_Index);
                        self.Gecco.Runs(1).Regions(1).Conditions(Run_Index).Deal;
                        
                        self.Gecco.Runs(1).Regions(1).Conditions(Run_Index).Initial.Outgassing = OutMatrix(:,Run_Index);
                    end
                elseif size(InitMatrix,2)>size(self.RunTableUI.Data,1);
                     self.UpdateLogBox("Fewer runs than initial conditions");
                    for Run_Index = 1:size(self.RunTableUI.Data,1);
                        self.Model.Conditions(Run_Index).Initial.Conditions = InitMatrix(:,Run_Index);
                        self.Model.Conditions(Run_Index).Deal;
                        
                        self.Model.Conditions(Run_Index).Initial.Outgassing = OutMatrix(:,Run_Index);
                    end
                end
                % Update the initial table titles
                if ~exist('src','var');
                    self.ExtendInitTableTitles;
                else                    
                    self.ExtendInitTableTitles(src,event);
                end
            end
        end
        
        %% Constant Table Callbacks
        % Updates the constant table definition
        function UpdateConstTable(self,src,event);
            % On cell change update the table
            for Run_Index = 1:numel(self.Gecco.Runs(1).Regions(1).Conditions);
                TableData = self.GetConstTableData();
                if size(TableData,2)>1;
                    self.UpdateLogBox("Can't display matrices");
                    Table = '';
                else
                    if ~isempty(TableData);
                        Table(:,Run_Index) = self.GetConstTableData();
                    else
                        Table = NaN;
                        self.UpdateLogBox("The value is empty");
                    end
                end
            end
%             Table = horzcat(self.Model.Conditions.Constant(1:end).(src.String{src.Value}));
            self.ConstTableUI.Data = Table;
        end
        function UpdateConstSelector(self,src,event);
            if nargin>1;
                self.ConstSelectorUI.String = fieldnames(self.Gecco.Runs(1).Regions(1).Conditions.Constants.(src.String{src.Value}));
            else
                self.ConstSelectorUI.String = fieldnames(self.Gecco.Runs(1).Regions(1).Conditions.Constants.(self.ConstGroupSelectorUI.String{self.ConstGroupSelectorUI.Value}));
            end
            self.ConstSelectorUI.Value = 1;
            self.UpdateConstTable();
        end
        % Makes changes to the original constants ###Will fail when horzcat
        % stacks things greater than size 1 in the second dimension
        function ConstTableEditCallback(self,src,event);
            Parameter = self.ConstSelectorUI.String{self.ConstSelectorUI.Value};
            Split_Parameter = strsplit(Parameter,'.');
            if numel(Split_Parameter)==1;
                self.Gecco.Runs(event.Indices(2)).Regions(1).Conditions.Constants.(Split_Parameter{1})(event.Indices(1),1) = event.NewData;
            elseif numel(Split_Parameter)==2;
                self.Gecco.Runs(event.Indices(2)).Regions(1).Conditions.Constants.(Split_Parameter{1}).(Split_Parameter{2})(event.Indices(1),1) = event.NewData;
            elseif numel(Split_Parameter)==3;
                self.Gecco.Runs(event.Indices(2)).Regions(1).Conditions.Constants.(Split_Parameter{1}).(Split_Parameter{2}).(Split_Parameter{3})(event.Indices(1),1) = event.NewData;
            elseif numel(Split_Parameter)==4;
                self.Gecco.Runs(event.Indices(2)).Regions(1).Conditions.Constants.(Split_Parameter{1}).(Split_Parameter{2}).(Split_Parameter{3}).(Split_Parameter{4})(event.Indices(1),1) = event.NewData;
            end
        end
        function ExtendConstTableTitles(self,src,event);
            Chunk_Number = numel(self.Gecco.Runs(self.SelectedRun).Chunks);
            for Chunk_Index = 1:Chunk_Number;
                CellTitle{Chunk_Index} = ['Chunk ',num2str(Chunk_Index)];
            end
            self.ConstTableUI.ColumnName = CellTitle;
        end
        function ConstIDs = GetConstIDs(self,Filename);
            FileID = netcdf.open(Filename);
            ConstGrpID = netcdf.inqNcid(FileID,'Constants');
            ConstIDs = netcdf.inqVarIDs(ConstGrpID);    
            netcdf.close(FileID);
        end
        function ConstNames = GetConstNames(self,Filename);
            ConstIDs = self.GetConstIDs(Filename);
            FileID = netcdf.open(Filename);
            ConstGrpID = netcdf.inqNcid(FileID,'Constants');
            for ConstNumber = 1:numel(ConstIDs);
                [ConstNames{ConstNumber},~,~,~] = netcdf.inqVar(ConstGrpID,ConstIDs(ConstNumber));
            end
            netcdf.close(FileID);
        end
        function Constant = LoadConstants(self,Filename);
            ConstIDs = self.GetConstIDs(Filename);
            ConstNames = self.GetConstNames(Filename);
            FileID = netcdf.open(Filename);
            ConstGrpID = netcdf.inqNcid(FileID,'Constants');
            for ConstNumber = 1:numel(ConstNames);
                Constant.(ConstNames{ConstNumber}) = netcdf.getVar(ConstGrpID,ConstIDs(ConstNumber));
            end
            
            netcdf.close(FileID);
        end
        function AssignConstantsToModel(self,Constants);
            Fieldnames = fieldnames(Constants);
            for Run_Index = 1:numel(self.Runs);
                for ConstNumber = 1:numel(Fieldnames);
                    if strcmp(Fieldnames{ConstNumber},'PIC_Burial');
                        self.Gecco.Runs(1).Regions(1).Conditions(Run_Index).Constant.(Fieldnames{ConstNumber}) = Constants.(Fieldnames{ConstNumber})(:,end,Run_Index);
                    else
                        self.Gecco.Runs(1).Regions(1).Conditions(Run_Index).Constant.(Fieldnames{ConstNumber}) = Constants.(Fieldnames{ConstNumber})(:,:,Run_Index);
                    end
                end
            end
        end
        function LoadConstsCallback(self,src,event);
            Constants = LoadConstants(self,self.InputFileUI.String);
            AssignConstantsToModel(self,Constants);
            
            Variables = LoadVariables(self,self.InputFileUI.String);
            AssignVariablesToModel(self,Variables);
            
            % Update the constant table titles
            if exist('src','var');
                self.ExtendConstTableTitles(src,event);
            end
        end
        
        %% PertTrans Callbacks
        function ChangePertTransTable(self,src,event);
            if strcmp(self.ChangeSelectorUI.String{self.ChangeSelectorUI.Value},'Perturbations');
                ChunkStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Chunks));
                ChunkCells = strsplit(ChunkStrings,' ');
                RegionStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Regions));
                RegionCells = strsplit(RegionStrings,' ');
                fmt = {RegionCells,ChunkCells};
                
                self.PertTransTableUI.ColumnFormat = fmt;
                self.PertTransTableUI.ColumnName = {'Region','Chunk','Type','Group','Parameter','Depth','Change To'};
                self.PertTransTableUI.CellEditCallback = @self.UpdatePerturbationTable;
                self.PertTransTableUI.CellSelectionCallback = @self.UpdateSelectedPert;
                self.PertTransTableUI.ColumnWidth = {50,40,60,60,110,40,180};
                
                if ~isempty(self.PertMatrix) && size(self.PertMatrix{1},1)>0;
                    self.PertTransTableUI.Data = self.PertMatrix{self.SelectedRun};
                end
            else
                ChunkStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Chunks));
                ChunkCells = strsplit(ChunkStrings,' ');
                RegionStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Regions));
                RegionCells = strsplit(RegionStrings,' ');
                fmt = {RegionCells,ChunkCells};
                
                self.PertTransTableUI.ColumnFormat = fmt;
                self.PertTransTableUI.ColumnName = {'Region','Chunk','Group','Parameter','Depth','Change To'};
                self.PertTransTableUI.CellEditCallback = @self.UpdateTransientTable;
                self.PertTransTableUI.CellSelectionCallback = @self.UpdateSelectedTransient;
                self.PertTransTableUI.ColumnWidth = {40,40,70,100,40,200};
                
                if ~isempty(self.TransMatrix) && size(self.PertMatrix{1},1)>0;
                    self.PertTransTableUI.Data = self.TransMatrix{self.SelectedRun};
                end
            end
        end
        function UpdatePertTransTable(self,src,event);
            if ~isempty(self.ChangeSelectorUI);
                if strcmp(self.ChangeSelectorUI.String{self.ChangeSelectorUI.Value},'Perturbations');
                    self.UpdatePerturbationTable(src,event);
                else
                    self.UpdateTransientTable(src,event);
                end
            end
        end
        function AddChange(self,src,event);
            if strcmp(self.ChangeSelectorUI.String{self.ChangeSelectorUI.Value},'Perturbations');
                self.AddPerturbation(src,event);
            else
                self.AddTransient(src,event);
            end
        end
        function UpdateSelectedChange(self,src,event);
            if strcmp(self.ChangeSelectorUI.String{self.ChangeSelectorUI.Value},'Perturbations');
                self.UpdateSelectedPert(src,event);
            else
                self.UpdateSelectedTransient(src,event);
            end
        end
        function LoadChanges(self,src,event);
            if ~(strcmp(self.SplashInputFileUI.String,"") || strcmp(self.SplashInputFileUI.String,"Input File"));
                if strcmp(self.ChangeSelectorUI.String{self.ChangeSelectorUI.Value},"Perturbations");
                    self.Gecco.LoadPerturbations(self.SplashInputFileUI.String);
                    for Perturbation_Index = 1:size(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Perturbations.Matrix,1);
                        self.PertMatrix{self.SelectedRun}(Perturbation_Index,:) = [{'1'},self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Perturbations.Matrix(Perturbation_Index,:)];
                    end
                    self.PertTransTableUI.Data = self.PertMatrix{self.SelectedRun};
                elseif strcmp(self.ChangeSelectorUI.String{self.ChangeSelectorUI.Value},"Transients");
                    self.Gecco.LoadTransients(self.SplashInputFileUI.String);
                    for Trans_Index = 1:size(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Transients.Matrix,1);
                        self.TransMatrix{self.SelectedRun}(Trans_Index,:) = [{'1'},self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Transients.Matrix(Trans_Index,:)];
                    end
                    self.PertTransTableUI.Data = self.TransMatrix{self.SelectedRun};
                else
                    self.UpdateLogBox("Selector value is not valid");
                end
            else
                self.UpdateLogBox("No input file specified");
            end
        end
        
        %% Perturbation Callbacks
        % Saves the selected row
        function UpdateSelectedPert(self,src,event);
            if ~isempty(event.Indices);
                self.SelectedPert = event.Indices(1);
            end
        end
        function AddPerturbation(self,src,event);
        % Adds perturbation
            % Add empty cell to table
            self.PertMatrix{self.SelectedRun} = [self.PertMatrix{self.SelectedRun};cell(1,7)];
            self.UpdatePerturbationTable(src,event);
        end
        function RemovePerturbation(self,src,event);
        % Removes perturbation
            % Removes the currently chosen row from the table
            self.PertTableUI.Data = [self.PertTableUI.Data(1:self.SelectedPert-1,:);self.PertTableUI.Data(self.SelectedPert+1:end,:)];
        end
        function UpdatePerturbationTable(self,src,event);
        % Updates the perturbation table display
            % If the caller is from adding a new Chunk
            if strcmp(src.Tag,'ChangeSelector');
            elseif strcmp(src.Tag,'AddChangeButton') || isempty(src.Tag) || strcmp(src.Tag,'TabChange');
                self.PertTransTableUI.Data = self.PertMatrix{self.SelectedRun};
            elseif strcmp(src.Tag,'ChunkTableAddButton') || strcmp(src.Tag,'ChunkTableRemoveButton');
                ChunkStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Chunks));
                ChunkCells = strsplit(ChunkStrings,' ');
                RegionStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Regions));
                RegionCells = strsplit(RegionStrings,' ');
                fmt = {RegionCells,ChunkCells};
                
                % Update the table - only the second column has changed
                set(self.PertTransTableUI,'ColumnFormat',fmt,...
                                          'ColumnEditable',[true,true,true,true,true,true,true]);
            % If the caller is a change to the table itself
            elseif strcmp(src.Tag,'PertTransTable');
                % Update all columns
                Index = str2double(self.PertTransTableUI.Data{event.Indices(1),1});
                ChunkStrings = num2str(1:numel(self.Gecco.Runs(Index).Chunks));
                ChunkCells = strsplit(ChunkStrings,' ');
                RegionStrings = num2str(1:numel(self.Gecco.Runs(Index).Regions));
                RegionCells = strsplit(RegionStrings,' ');
%                 InitNames = fieldnames(self.Gecco.Runs(1).Regions(1).Conditions.Initial);
%                 ConstNames = fieldnames(self.Gecco.Runs(1).Regions(1).Conditions.Constant);
                if ~isempty(src.Data{self.SelectedPert,3});
                    if strcmp(src.Data{self.SelectedPert,3},'Constants');
                        Group_Names = fieldnames(self.Gecco.Runs(1).Regions(1).Conditions.(src.Data{self.SelectedPert,3}))';
                    else
                        Group_Names = {'Output'};
                        Names = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(str2double(src.Data{self.SelectedPert,1})).Conditions.(src.Data{self.SelectedPert,3}))';
                    end
                end
                if ~isempty(src.Data{self.SelectedPert,4}) && event.Indices(2)>3;
                    if strcmp(src.Data{self.SelectedPert,3},'Constants');
                        Names = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(str2double(src.Data{self.SelectedPert,1})).Conditions.(src.Data{self.SelectedPert,3}).(src.Data{self.SelectedPert,4}))';
                    else
%                         Group_Names = 'Outputs';
%                         src.Data{4} = 'Outputs';
                    end
                end
                if ~isempty(src.Data{5});
                    Number = 5; %numel(self.Gecco.Runs(self.SelectedRun).Regions(str2double(src.Data{2})).Conditions.(src.Data{3}).(src.Data{4}));
                    NumCells = strsplit(num2str(1:Number),' ');
                end

                if event.Indices(2) == 1;
                    fmt = {RegionCells,ChunkCells};
                elseif event.Indices(2) == 2;
                    fmt = {RegionCells,ChunkCells,{'Constants','Initials'}};
                elseif event.Indices(2) == 3;
                    if strcmp(src.Data{event.Indices(1),3},"Constants");
                        Group_Names = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(str2double(src.Data{event.Indices(1),1})).Conditions.(event.NewData))';
                        fmt = {RegionCells,ChunkCells,{'Constants','Initials'},Group_Names};
                    else
                        Group_Names = {'Output'};
                        Names = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(str2double(src.Data{self.SelectedPert,1})).Conditions.(src.Data{self.SelectedPert,3}))';
                        fmt = {RegionCells,ChunkCells,{'Constants','Initials'},Group_Names,Names};
                    end
                    elseif event.Indices(2) ==4;
                        if strcmp(src.Data{event.Indices(1),3},"Constants");
                            Names = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(str2double(src.Data{self.SelectedPert,1})).Conditions.(src.Data{self.SelectedPert,3}).(src.Data{self.SelectedPert,4}))';
                        else
                            Names = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(str2double(src.Data{self.SelectedPert,1})).Conditions.(src.Data{self.SelectedPert,3}))';
                        end
                        fmt = {RegionCells,ChunkCells,{'Constants','Initials'},Group_Names,Names};
                elseif event.Indices(2) == 5;
                    if strcmp(src.Data{self.SelectedPert,3},'Constants');
                        Number = numel(self.Gecco.Runs(self.SelectedRun).Regions(str2double(src.Data{self.SelectedPert,1})).Conditions.(src.Data{self.SelectedPert,3}).(src.Data{self.SelectedPert,4}));
                        NumCells = [':',strsplit(num2str(1:Number),' ')];
                    else
                        Number = numel(self.Gecco.Runs(self.SelectedRun).Regions(str2double(src.Data{self.SelectedPert,1})).Conditions.(src.Data{self.SelectedPert,3}).(src.Data{self.SelectedPert,5}));
                        NumCells = [':',strsplit(num2str(1:Number),' ')];
                    end
                        fmt = {RegionCells,ChunkCells,{'Constants','Initials'},Group_Names,Names,NumCells};
                else
                    fmt = {RegionCells,ChunkCells,{'Constants','Initials'},Group_Names,Names,NumCells,'char'};
                end
                self.PertTransTableUI.ColumnFormat = fmt;
            else
            % Otherwise error out
                self.UpdateLogBox("Unknown error in perturbation table update");
            end
            
            if ~(strcmp(src.Tag,'ChunkTableAddButton') || strcmp(src.Tag,'ChunkTableRemoveButton') || strcmp(src.Tag,'AddChangeButton') || strcmp(src.Tag,'TabChange'));
                self.PertMatrix{self.SelectedRun} = src.Data;
            end
        end
        function LoadPerts(self,src,event);
            Flag = 0;
            if isempty(self.Model);
                self.UpdateLogBox("Please instantiate model first");
            elseif isempty(self.RunTableUI.Data);
                self.UpdateLogBox("No runs to load");
            else
                if isempty(self.InputFileUI.String);
                    self.SetInputFilepath;
                end
                PertMatrix = ncread(self.InputFileUI.String,'/Replication/Perturbation_Matrix');
                MaxRuns = size(self.RunTableUI.Data,1);
                if size(PertMatrix,2)~=1;
                    for PMIndex = 1:size(PertMatrix,1);
                        CurrentPert = strsplit(strtrim(PertMatrix(PMIndex,:)),',');
                        MaxChunks = numel(self.Runs(str2double(CurrentPert{1})).Chunks);
                        if ~(str2double(CurrentPert{1})>MaxRuns) && ~(str2double(CurrentPert{2})>MaxChunks);
                            PertExists = sum(strcmp(CurrentPert{3},self.PertTableUI.Data(:,3)) & str2double(CurrentPert(1))==str2double(self.PertTableUI.Data(:,1)) & str2double(CurrentPert{2})==str2double(self.PertTableUI.Data(:,2)));
                            if ~PertExists;
                                self.Gecco.Runs(str2double(CurrentPert{1})).Chunks(str2double(CurrentPert{2})).AddPerturbation(CurrentPert{3},CurrentPert{4},CurrentPert{5});
                                self.PertTableUI.Data = [self.PertTableUI.Data;CurrentPert];
                            end
                        else
                            Flag = 1;
                        end
                    end
                else
                    self.UpdateLogBox("No perturbations to load");
                end
                if Flag==1;
                    self.UpdateLogBox("Some perturbations were skipped");
                end
            end
        end
        function Perturbations = GetPerturbations(self,src,event);
            if ~isempty(self.PertMatrix) && ~isempty(self.PertMatrix{self.SelectedRun});
                Perturbations = self.PertMatrix{self.SelectedRun};
            else
                Perturbations = cell(0,7);
            end
        end
        
        %% Transients Table Callbacks
        % Adds a transient
        function AddTransient(self,src,event);
            self.TransMatrix{self.SelectedRun} = [self.TransMatrix{self.SelectedRun};cell(1,6)];
            self.UpdateTransientTable(src,event);
        end
        function RmTransient(self,src,event);
        % Removes currently selected transient
            self.TransTableUI.Data = [self.TransTableUI.Data(1:self.TransIndices(1)-1,:);self.TransTableUI.Data((self.TransIndices(1)+1):end,:)];
        end
        function UpdateSelectedTransient(self,src,event);
        % Stores the currently selected variable
            self.TransIndices = event.Indices;
        end
        function Transients = GetTransients(self,src,event);
            % Sets the currently specified variables
            if ~isempty(self.TransMatrix);
                Transients = self.TransMatrix{self.SelectedRun};
            else
                Transients = cell(0,6);
            end
        end
        function UpdateTransientTable(self,src,event);
            % Updates the data for the variable table
%             try
                % If the call comes from the addition of a Chunk
                if strcmp(src.Tag,'AddChangeButton');
                    self.PertTransTableUI.Data = self.TransMatrix{self.SelectedRun};           
                elseif strcmp(src.Tag,'ChunkTableAddButton') || strcmp(src.Tag,'ChunkTableRemoveButton');
                    % Just process the second column
                    RegionStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Regions));
                    RegionCells = strsplit(RegionStrings,' ');
                    ChunkStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Chunks));
                    ChunkCells = [':',strsplit(ChunkStrings,' ')];
                    fmt = {RegionCells,ChunkCells};
                    self.PertTransTableUI.ColumnFormat = fmt;
                    % Otherwise, if the call is from the table itself
                elseif strcmp(src.Tag,'PertTransTable') && isempty(event.Indices);
                    
                elseif strcmp(src.Tag,'PertTransTable') && event.Indices(2)==2;
                    % Process all the columns
                    RegionStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Regions));
                    RegionCells = strsplit(RegionStrings,' ');
                    ChunkStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Chunks));
                    ChunkCells = [':',strsplit(ChunkStrings,' ')];
                    ParamGroupNames = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Constants)';
                    fmt = {RegionCells,ChunkCells,ParamGroupNames};
                    self.PertTransTableUI.ColumnFormat = fmt;
                    self.PertTransTableUI.ColumnEditable = [true,true,true,false,true,true,true];
                elseif strcmp(src.Tag,'PertTransTable') && event.Indices(2)==3;
                    % Process all the columns
                    RegionStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Regions));
                    RegionCells = strsplit(RegionStrings,' ');
                    ChunkStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Chunks));
                    ChunkCells = [':',strsplit(ChunkStrings,' ')];
                    ParamGroupNames = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Constants)';
                    ParamNames = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Constants.(src.Data{self.TransIndices(1),3}))';
                    fmt = {RegionCells,ChunkCells,ParamGroupNames,ParamNames};
                    self.PertTransTableUI.ColumnFormat = fmt;
                    self.PertTransTableUI.ColumnEditable = [true,true,true,true,true,true,true];

                elseif strcmp(src.Tag,'PertTransTable') && event.Indices(2)==4;
                    % Process all the columns
                    RegionStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Regions));
                    RegionCells = strsplit(RegionStrings,' ');
                    ChunkStrings = num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Chunks));
                    ChunkCells = [':',strsplit(ChunkStrings,' ')];
                    ParamGroupNames = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Constants)';
                    ParamNames = fieldnames(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Constants.(src.Data{self.TransIndices(1),3}))';
                    ParamNums = [{':'},strsplit(num2str(numel(self.Gecco.Runs(self.SelectedRun).Regions(1).Conditions.Constants.(src.Data{self.TransIndices(1),3}).(src.Data{self.TransIndices(1),4}))'),' ')];
                    fmt = {RegionCells,ChunkCells,ParamGroupNames,ParamNames,ParamNums,'char'};
                    self.PertTransTableUI.ColumnFormat = fmt;
                    self.PertTransTableUI.ColumnEditable = [true,true,true,false,true,true,true];
                end
                if ~(strcmp(src.Tag,'ChunkTableAddButton') || strcmp(src.Tag,'ChunkTableRemoveButton') || strcmp(src.Tag,'AddChangeButton'));
                    self.TransMatrix{self.SelectedRun} = src.Data;
                end
%                 catch
%                 self.UpdateLogBox("Unexpected error with variable table");
%             end
        end
        function LoadTransients(self,src,event);
            if isempty(self.Gecco);
                self.UpdateLogBox("Please instantiate model first");
            elseif isempty(self.RunTableUI.Data);
                self.UpdateLogBox("No runs to load");
            else
                if isempty(self.InputFileUI.String);
                    self.SetInputFilepath;
                end
                TransMatrix = ncread(self.InputFileUI.String,'/Replication/Variable_Matrix');
                if size(TransMatrix,2)~=1;
                    for VMIndex = 1:size(TransMatrix,1);
                        CurrentVar = strsplit(strtrim(TransMatrix(VMIndex,:)),',');
                        if numel(CurrentVar)>3;
                            StringCat = [strcat(CurrentVar(3:end-1),','),CurrentVar(end)];
                            CurrentVar{3} = strcat([StringCat{:}]);
                            CurrentVar = CurrentVar(1:3);
                        end
                        self.Gecco.Runs(1).Regions(1).Conditions.AddVariable(CurrentVar{1},CurrentVar{2},CurrentVar{3});
                        self.TransTableUI.Data = [self.TransTableUI.Data;CurrentVar];
                    end
                else
                    self.UpdateLogBox("No variables to load");
                end
            end
        end
        function TransIDs = GetTransIDs(self,Filename);
            FileID = netcdf.open(Filename);
            VarGrpID = netcdf.inqNcid(FileID,'Variables');
            TransIDs = netcdf.inqVarIDs(VarGrpID);    
            netcdf.close(FileID);
        end
        function TransNames = GetTransNames(self,Filename);
            VarIDs = self.GetVarIDs(Filename);
            if ~isempty(VarIDs);
                FileID = netcdf.open(Filename);
                VarGrpID = netcdf.inqNcid(FileID,'Variables');
                for VarNumber = 1:numel(VarIDs);
                    [TransNames{VarNumber},~,~,~] = netcdf.inqVar(VarGrpID,VarIDs(VarNumber));
                end
                netcdf.close(FileID);
            else
                TransNames = [];
            end
        end
        function Transient = LoadTrans(self,Filename);
            VarIDs = self.GetVarIDs(Filename);
            VarNames = self.GetVarNames(Filename);
            if ~isempty(VarNames);
                FileID = netcdf.open(Filename);
                VarGrpID = netcdf.inqNcid(FileID,'Variables');
                for VarNumber = 1:numel(VarNames);
                    Transient.(VarNames{VarNumber}) = netcdf.getVar(VarGrpID,VarIDs(VarNumber));
                end
                
                netcdf.close(FileID);
            else
                Transient = [];
            end
        end
        function AssignTransientsToModel(self,Variables);
            if ~isempty(Variables);
                Fieldnames = fieldnames(Variables);
                for Run_Index = 1:numel(self.Runs);
                    for VarNumber = 1:numel(Fieldnames);
                        self.Gecco.Runs(1).Regions(1).Conditions(Run_Index).Constant.(Fieldnames{VarNumber}) = Variables.(Fieldnames{VarNumber})(:,end,Run_Index);
                    end
                end
            end
        end
        
        %% Regional Callbacks
        function AddRegionCallback(self,src,event);
            self.Gecco.Runs(self.SelectedRun).AddRegion();
            self.UpdateLogBox("Region added");
        end
        
        %% Finalise
        % What to do just before the model runs
        function Finalise(self);
            for RunIndex = 1:numel(self.Runs);
                for ChunkIndex = 1:numel(self.Runs(RunIndex).Chunks);
                    self.Runs(RunIndex).Chunks(ChunkIndex).Perturbations = [];
                end
            end
            % Perturbations
            for Pert_Index = 1:size(self.PertTableUI.Data,1);
                self.Runs(str2double(self.PertTableUI.Data{Pert_Index,1})).Chunks(str2double(self.PertTableUI.Data{Pert_Index,2})).AddPerturbation(self.PertTableUI.Data{Pert_Index,3},self.PertTableUI.Data{Pert_Index,4},self.PertTableUI.Data{Pert_Index,5});
            end
            
            % Variables
            for Run_Index = 1:numel(self.Model.Conditions);
                self.Regions(1).Conditions(Run_Index).RmVariables;
            end
            
            for Variable_Index = 1:size(self.TransTableUI.Data,1);
                Input1 = self.TransTableUI.Data{Variable_Index,1};
                Input2 = str2double(self.TransTableUI.Data{Variable_Index,2});
                Input3 = [self.TransTableUI.Data{Variable_Index,3}];
                
                self.Model.Conditions.AddVariable(Input1,Input2,Input3);
            end
        end        
        function ReplicationCells = MakeReplicationCells(self);
            RunMatrix = self.RunTableUI.Data;
            PertMatrix = char(join(self.PertTableUI.Data,','));
            if size(self.TransTableUI.Data,1)>0 && isempty(self.TransTableUI.Data{2});
                TransMatrix = char(join(self.TransTableUI.Data([1,3:end]),','));
            else
                TransMatrix = char(join(self.TransTableUI.Data,','));
            end
            for Run_Index = 1:numel(self.Gecco.Runs(1).Regions(1).Conditions);
                InitMatrix(:,Run_Index) = self.Gecco.Runs(1).Regions(1).Conditions(Run_Index).Initials.Conditions;
            end
            ReplicationCells = {RunMatrix,PertMatrix,TransMatrix,InitMatrix};
        end
        
        %% Run Model
        function RunModel(self,src,event);
            self.Gecco.UsedGUIFlag = 1;
%             self.Gecco.ParseGUIPerturbations(self.PertMatrix);
%             self.Gecco.ParseGUITransients(self.TransMatrix);
            self.Gecco.RunModel(self);
        end

        %% Log box
        function UpdateLogBox(self,Message,Run_Numbers);
            if nargin<3;
                Run_Numbers = self.SelectedRun;
            end
            for Run_Index = 1:numel(Run_Numbers);
                if ~isempty(self.LogMessages{Run_Numbers(Run_Index)});
                    self.LogMessages{Run_Numbers(Run_Index)} = [self.LogMessages{Run_Numbers(Run_Index)};Message];
                else
                    self.LogMessages{Run_Numbers(Run_Index)} = Message;
                end
            end
            self.LogBoxUI.String = self.LogMessages{self.SelectedRun};
            LogBoxObj = findjobj(self.LogBoxUI);
            LogBoxEdit = LogBoxObj.getComponent(0).getComponent(0);
            LogBoxEdit.setCaretPosition(LogBoxEdit.getDocument.getLength);
            drawnow;
        end
        
        %% Display functions
        function TabChangeCallback(self,src,event);
            if nargin<3 || strcmp(event.NewValue.Title,'Splash');
                self.DrawSplashPage();
            elseif strcmp(event.NewValue.Title,'+');
                event.NewValue.Title = ['Run ',num2str(numel(self.RunTabHandles))];
                self.RunTabHandles = [self.RunTabHandles,{uitab('Parent',self.TabGroupHandle,'Title','+')}];
                uistack(self.TabGroupHandle.Children(end-1),'bottom');
                self.SelectedTab = str2double(event.NewValue.Title(end));
                self.SelectedRun = self.SelectedTab;
                self.AddRunCallback();
                self.DrawSettings();
            elseif ~strcmp(event.NewValue.Title,'Plot Data');
                self.SelectedTab = str2double(event.NewValue.Title(end));
                self.SelectedRun = self.SelectedTab;
                self.RebuildTable(src,event);
                self.DrawSettings();
            elseif strcmp(event.NewValue.Title,'Plot Data');
                if ~isempty(self.Gecco);
                    if ~isempty(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time);
                        self.SubplotIndex=1;
                        self.SelectPlot();                     
                    end
                end
            end
        end
        function DrawSplashPage(self);
            Ax = axes('Parent',self.SplashTabHandle,'Position',[0.05,0.22,0.9,0.75]);
            imshow(self.Logo,'InitialMagnification',12,'Parent',Ax);
            %% Filepath                                       
                self.SplashInputFileUI = uicontrol('Style','edit',...
                                                   'Tag',"SplashInputFile",...
                                                   'Units','Normalized',...
                                                   'Position',[0.166,0.165,0.668,0.035],...
                                                   'HorizontalAlignment','left',...
                                                   'ForegroundColor',self.Colours.grey,...
                                                   'Enable','Inactive',...
                                                   'String',"Input File",...
                                                   'ButtonDownFcn',@self.SelectiveClear,...
                                                   'Callback',@self.SetFilepath,...
                                                   'Parent',self.SplashTabHandle);
                self.SplashOutputFilepathUI = uicontrol('Style','edit',...
                                                        'Tag',"SplashOutputFilepath",...
                                                        'Units','Normalized',...
                                                        'Position',self.SplashInputFileUI.Position+[0,-0.05,0,0],...
                                                        'HorizontalAlignment','Left',...
                                                        'String',"Output Filepath",...
                                                        'ForegroundColor',self.Colours.grey,...
                                                        'Enable','Inactive',...
                                                        'ButtonDownFcn',@self.SelectiveClear,...
                                                        'Callback',@self.SetFilepath,...
                                                        'Parent',self.SplashTabHandle);
                self.SplashOutputFilenameUI = uicontrol('Style','edit',...
                                                        'Tag',"SplashOutputFilename",...
                                                        'Units','Normalized',...
                                                        'Position',self.SplashOutputFilepathUI.Position+[0,-0.05,0,0],...
                                                        'HorizontalAlignment','Left',...
                                                        'ForegroundColor',self.Colours.grey,...
                                                        'Enable','Inactive',...
                                                        'String',"Output Filename",...
                                                        'ButtonDownFcn',@self.SelectiveClear,...
                                                        'Callback',@self.SetFilepath,...
                                                        'Parent',self.SplashTabHandle);
                self.SplashShouldSaveTickboxUI = uicontrol('Style','Checkbox',...
                                                           'Tag',"ShouldSaveTickbox",...
                                                           'Value',self.Gecco.ShouldSaveFlag,...
                                                           'Units','Normalized',...
                                                           'Position',self.SplashOutputFilenameUI.Position+[0,-0.05,0,0],...
                                                           'HorizontalAlignment','Left',...
                                                           'String',"Save",...
                                                           'Callback',@self.SetSaveFlag,...
                                                           'Parent',self.SplashTabHandle);
                self.SplashSaveToSameFileTickboxUI = uicontrol('Style','Checkbox',...
                                                               'Tag',"SaveToSameFileTickbox",...
                                                               'Value',self.Gecco.SaveToSameFileFlag,...
                                                               'Units','Normalized',...
                                                               'Position',self.SplashShouldSaveTickboxUI.Position+[0.16,0,0,0],...
                                                               'HorizontalAlignment','Left',...
                                                               'String',"Save To Same File",...
                                                               'Callback',@self.SetSaveFlag,...
                                                               'Parent',self.SplashTabHandle);
                self.SplashSaveByRunsTickboxUI = uicontrol('Style','Checkbox',...
                                                           'Tag',"SaveByRunsTickbox",...
                                                           'Value',self.Gecco.SaveToRunFilesFlag,...
                                                           'Units','Normalized',...
                                                           'Position',self.SplashSaveToSameFileTickboxUI.Position+[0.16,0,0,0],...
                                                           'HorizontalAlignment','Left',...
                                                           'String',"Save Each Run To Same File",...
                                                           'Callback',@self.SetSaveFlag,...
                                                           'Parent',self.SplashTabHandle);
                self.SplashSaveByRegionsTickboxUI = uicontrol('Style','Checkbox',...
                                                              'Tag',"SaveByRunsTickbox",...
                                                              'Value',self.Gecco.SaveToRegionFilesFlag,...
                                                              'Units','Normalized',...
                                                              'Position',self.SplashSaveByRunsTickboxUI.Position+[0.16,0,0,0],...
                                                              'HorizontalAlignment','Left',...
                                                              'String',"Save Each Region To Same File",...
                                                              'Callback',@self.SetSaveFlag,...
                                                              'Parent',self.SplashTabHandle);
                                                     
                SplashInputFileBrowseButton = uicontrol('Style','Pushbutton',...
                                                        'Tag',"SplashInputFileBrowseButton",...
                                                        'String','Browse',...
                                                        'Units','Normalized',...
                                                        'Position',[self.SplashInputFileUI.Position(1)+0.668-0.04,self.SplashInputFileUI.Position(2),0.045,0.035],...
                                                        'Callback',@self.GetAndSetFilepath,...
                                                        'Parent',self.SplashTabHandle);
                SplashOutputFilepathBrowseButton = uicontrol('Style','Pushbutton',...
                                                             'Tag',"SplashOutputFilepathBrowseButton",...
                                                             'String','Browse',...
                                                             'Tag',"SplashOutputFilepathBrowseButton",...
                                                             'Units','Normalized',...
                                                             'Position',SplashInputFileBrowseButton.Position+[0,-0.0502,0,0],...
                                                             'Callback',@self.GetAndSetFilepath,...
                                                             'Parent',self.SplashTabHandle);
                self.SplashFilenameWarningUI = uicontrol('Style','text',...
                                                         'Units','Normalized',...
                                                         'Position',[SplashOutputFilepathBrowseButton.Position(1),SplashOutputFilepathBrowseButton.Position(2)-0.06,0.1,0.05],...
                                                         'HorizontalAlignment','left',...
                                                         'String',' ',...
                                                         'Parent',self.SplashTabHandle);
                                                     
                self.SetSplashPaths();
        end
        function DrawSettings(self);
        %% Filepath
                self.InputFileUI = uicontrol('Style','edit',...
                                             'Tag',"InputFile",...
                                             'Units','Normalized',...
                                             'Position',[0.017,0.91,0.465,0.035],...
                                             'HorizontalAlignment','left',...
                                             'String',"Input File",...
                                             'ForegroundColor',self.Colours.grey,...
                                             'Enable','Inactive',...
                                             'ButtonDownFcn',@self.SelectiveClear,...
                                             'Callback',@self.SetFilepath,...
                                             'Parent',self.RunTabHandles{self.SelectedTab});
                self.OutputFilepathUI = uicontrol('Style','edit',...
                                                  'Tag',"OutputFilepath",...
                                                  'Units','Normalized',...
                                                  'Position',self.InputFileUI.Position+self.TextBoxSpacing,...
                                                  'HorizontalAlignment','Left',...
                                                  'String',"Output Filepath",...
                                                  'ForegroundColor',self.Colours.grey,...
                                                  'Enable','Inactive',...
                                                  'ButtonDownFcn',@self.SelectiveClear,...
                                                  'Callback',@self.SetFilepath,...
                                                  'Parent',self.RunTabHandles{self.SelectedTab});
                self.OutputFilenameUI = uicontrol('Style','edit',...
                                                  'Tag',"OutputFilename",...
                                                  'Units','Normalized',...
                                                  'Position',self.OutputFilepathUI.Position+self.TextBoxSpacing,...
                                                  'HorizontalAlignment','Left',...
                                                  'String',"Output Filename",...
                                                  'ForegroundColor',self.Colours.grey,...
                                                  'Enable','Inactive',...
                                                  'ButtonDownFcn',@self.SelectiveClear,...
                                                  'Callback',@self.SetFilepath,...
                                                  'Parent',self.RunTabHandles{self.SelectedTab});
                                              
                InputFileBrowseButton = uicontrol('Style','Pushbutton',...
                                                  'Tag',"InputFileBrowseButton",...
                                                  'String','Browse',...
                                                  'Units','Normalized',...
                                                  'Position',[0.44,self.InputFileUI.Position(2),0.046,0.035],...
                                                  'Callback',@self.SetInputFilepath,...
                                                  'Parent',self.RunTabHandles{self.SelectedTab});
                OutputFilepathBrowseButton = uicontrol('Style','Pushbutton',...
                                                       'Tag',"OutputFilepathBrowseButton",...
                                                       'String','Browse',...
                                                       'Units','Normalized',...
                                                       'Position',InputFileBrowseButton.Position+self.TextBoxSpacing,...
                                                       'Callback',@self.GetAndSetFilepath,...
                                                       'Parent',self.RunTabHandles{self.SelectedTab});         
                self.FilenameWarningUI = uicontrol('Style','text',...
                                                   'Units','Normalized',...
                                                   'Position',OutputFilepathBrowseButton.Position+self.TextBoxSpacing,...
                                                   'HorizontalAlignment','left',...
                                                   'String',' ',...
                                                   'Parent',self.RunTabHandles{self.SelectedTab});  
                
                self.RunSelectorLabelUI = uicontrol('Style','text',...
                                                    'Units','Normalized',...
                                                    'Position',[self.OutputFilenameUI.Position(1)-0.05,self.OutputFilenameUI.Position(2)-0.11,0.14,0.09],...
                                                    'String','Run',...
                                                    'Parent',self.RunTabHandles{self.SelectedTab});
                self.RunSelectorUI = uicontrol('Style','popupmenu',...
                                               'Units','Normalized',...
                                               'Position',[self.RunSelectorLabelUI.Position(1)+0.1,self.RunSelectorLabelUI.Position(2),self.DropDownSize],...
                                               'String','-',...
                                               'Callback','',...
                                               'Parent',self.RunTabHandles{self.SelectedTab});
                self.RegionSelectorLabelUI = uicontrol('Style','text',...
                                                    'Units','Normalized',...
                                                    'Position',[self.RunSelectorLabelUI.Position(1)+0.25,self.RunSelectorLabelUI.Position(2),0.05,0.09],...
                                                    'String','Region',...
                                                    'Parent',self.RunTabHandles{self.SelectedTab});
                self.RegionSelectorUI = uicontrol('Style','popupmenu',...
                                               'Units','Normalized',...
                                               'Position',[self.RegionSelectorLabelUI.Position(1)+0.05,self.RegionSelectorLabelUI.Position(2),self.DropDownSize],...
                                               'String','-',...
                                               'Callback','',...
                                               'Parent',self.RunTabHandles{self.SelectedTab});
                %% Run Table
                RunTableLabelUI = uicontrol('Style','text',...
                                            'Units','Normalized',...
                                            'Position',[0.0172,0.63,0.14,0.09],...
                                            'String','Chunks',...
                                            'HorizontalAlignment','Left',...
                                            'Parent',self.RunTabHandles{self.SelectedTab});
                self.RunTableUI = uitable(self.Handle,...
                                          'Data',self.RunTableUI.Data,...
                                          'Units','Normalized',...
                                          'Position',[RunTableLabelUI.Position(1)+0.08,RunTableLabelUI.Position(2)-0.12,self.BoxSize{1}(1),self.BoxSize{1}(2)],...
                                          'CellSelectionCallback',@self.UpdateRunIndices,...
                                          'CellEditCallback',@self.ChunkTableEditCallback,...
                                          'ColumnName',{'Start','End','Step','Start','End','Step'},...
                                          'ColumnWidth',{60,60,40,60,60,40},...
                                          'ColumnEditable',[true,true,true,true,true,true,true],...
                                          'Parent',self.RunTabHandles{self.SelectedTab});
                ChunkTableAddButtonUI = uicontrol('Style','pushbutton',...
                                                  'Units','Normalized',...
                                                  'Position',[RunTableLabelUI.Position(1)+0.025,RunTableLabelUI.Position(2),self.ButtonAddRmSize],...
                                                  'String','+',...
                                                  'Callback',@self.AddChunkCallback,...
                                                  'Tag','ChunkTableAddButton',...
                                                  'Parent',self.RunTabHandles{self.SelectedTab});
                RmChunkButtonUI = uicontrol('Style','pushbutton',...
                                               'Units','Normalized',...
                                               'Position',ChunkTableAddButtonUI.Position+[0,-self.ButtonThinSpacing(2),0,0],...
                                               'String','-',...
                                               'Callback',@self.RunTableRemoveEntry,...
                                               'Tag','ChunkTableRemoveButton',...
                                               'Parent',self.RunTabHandles{self.SelectedTab});
                RunLoadButtonUI = uicontrol('Style','pushbutton',...
                                            'Units','Normalized',...
                                            'Position',[RunTableLabelUI.Position(1),RmChunkButtonUI.Position(2)-self.ButtonThinSpacing(2),self.ButtonSize],...
                                            'String','Load',...
                                            'Callback',@self.LoadRuns,...
                                            'Tag','RunLoadButton',...
                                            'Parent',self.RunTabHandles{self.SelectedTab});
                  
                  %% Conditions
                  CondTableLabelUI = uicontrol('Style','text',...
                                               'Units','Normalized',...
                                               'Position',[0.5,0.88,0.1369,0.0874],...
                                               'String','Conditions',...
                                               'HorizontalAlignment','Left',...
                                               'Parent',self.RunTabHandles{self.SelectedTab});                                  
                  self.CondTypeSelectorUI = uicontrol('Style','popupmenu',...
                                                      'Units','Normalized',...
                                                      'Position',[CondTableLabelUI.Position(1)+0.08,CondTableLabelUI.Position(2)+0.01,self.DropDownSize],...
                                                      'String',{'Initials','Constants','Functionals'},...
                                                      'Callback',@self.UpdateCondGroupSelector,...
                                                      'Parent',self.RunTabHandles{self.SelectedTab});                                                  
                  self.CondGroupSelectorUI = uicontrol('Style','popupmenu',...
                                                       'Units','Normalized',...
                                                       'Position',self.CondTypeSelectorUI.Position+[self.DropDownHorzSpacing,0,0,0],...
                                                       'String','',...
                                                       'Callback',@self.UpdateCondSelector,...
                                                       'Parent',self.RunTabHandles{self.SelectedTab});
                  self.UpdateCondGroupSelector();
                  
                  self.CondSelectorUI = uicontrol('Style','popupmenu',...
                                                  'Units','Normalized',...
                                                  'Position',self.CondGroupSelectorUI.Position+[self.DropDownHorzSpacing,0,0,0],...
                                                  'Tag','CondSelectorUI',...
                                                  'String','',...
                                                  'Callback',@self.UpdateCondTable,...
                                                  'Parent',self.RunTabHandles{self.SelectedTab});
                  self.UpdateCondSelector();
                  
                  CondTypeLoadButtonUI = uicontrol('Style','pushbutton',...
                                            'Units','Normalized',...
                                            'Position',[CondTableLabelUI.Position(1),CondTableLabelUI.Position(2)+0.02,self.ButtonSize],...
                                            'String','Load Type',...
                                            'Callback',@self.LoadCondType,...
                                            'Parent',self.RunTabHandles{self.SelectedTab});
                  CondGroupLoadButtonUI = uicontrol('Style','pushbutton',...
                                            'Units','Normalized',...
                                            'Position',CondTypeLoadButtonUI.Position+[0,-self.ButtonThinSpacing(2),0,0],...
                                            'String','Load Group',...
                                            'Callback',@self.LoadCondGroup,...
                                            'Parent',self.RunTabHandles{self.SelectedTab});
                  CondLoadButtonUI = uicontrol('Style','pushbutton',...
                                            'Units','Normalized',...
                                            'Position',CondGroupLoadButtonUI.Position+[0,-self.ButtonThinSpacing(2),0,0],...
                                            'String','Load Condition',...
                                            'Callback',@self.LoadCond,...
                                            'Parent',self.RunTabHandles{self.SelectedTab});
                  CondLoadFinalButtonUI = uicontrol('Style','pushbutton',...
                                            'Units','Normalized',...
                                            'Position',CondLoadButtonUI.Position+[0,-self.ButtonThinSpacing(2),0,0],...
                                            'String','Load Final',...
                                            'Callback',@self.LoadCondFinal,...
                                            'Parent',self.RunTabHandles{self.SelectedTab});
                  
                  self.CondTableUI = uitable(self.Handle,...
                                            'Data',self.GetCondTableData(),...
                                            'Units','Normalized',...
                                            'Position',[CondTableLabelUI.Position(1)+0.08,CondTableLabelUI.Position(2)-0.12,self.BoxSize{1}(1),self.BoxSize{1}(2)],...
                                            'ColumnEditable',[true,true,true,true,true,true,true],...
                                            'ColumnName',{'Region 1'},...
                                            'CellEditCallback',@self.CondTableEditCallback,...
                                            'Parent',self.RunTabHandles{self.SelectedTab});

                %% PertTrans Table                
                ChangesTableLabelUI = uicontrol('Style','text',...
                                             'Units','Normalized',...
                                             'Position',[0.5,0.63,0.1369,0.0874],...
                                             'String','Changes',...
                                             'HorizontalAlignment','Left',...
                                             'Parent',self.RunTabHandles{self.SelectedTab});
                self.ChangeSelectorUI = uicontrol('Style','popupmenu',...
                                                  'Units','Normalized',...
                                                  'Position',[ChangesTableLabelUI.Position(1)+0.08,ChangesTableLabelUI.Position(2)+0.01,self.DropDownSize],...
                                                  'Tag','ChangeSelector',...
                                                  'String',{'Perturbations','Transients'},...
                                                  'Callback',@self.ChangePertTransTable,...
                                                  'Parent',self.RunTabHandles{self.SelectedTab});                                         
                 AddChangeButtonUI = uicontrol('Style','pushbutton',...
                                               'Units','Normalized',...
                                               'Position',[ChangesTableLabelUI.Position(1)+0.02,ChangesTableLabelUI.Position(2),self.ButtonAddRmSize],...
                                               'Tag','AddChangeButton',...
                                               'String','+',...
                                               'Callback',@self.AddChange,...
                                               'Parent',self.RunTabHandles{self.SelectedTab});                 
                 RmChangeButtonUI = uicontrol('Style','pushbutton',...
                                              'Units','Normalized',...
                                              'Position',AddChangeButtonUI.Position+[0,-self.ButtonThinSpacing(2),0,0],...
                                              'Tag','RmChangeButton',...
                                              'String','-',...
                                              'Callback',@self.RemoveChange,...
                                              'Parent',self.RunTabHandles{self.SelectedTab});
                 LoadChangeButtonUI = uicontrol('Style','pushbutton',...
                                                'Units','Normalized',...
                                                'Position',[ChangesTableLabelUI.Position(1),RmChangeButtonUI.Position(2)-self.ButtonThinSpacing(2),self.ButtonSize],...
                                                'String','Load Change',...
                                                'Callback',@self.LoadChanges,...
                                                'Parent',self.RunTabHandles{self.SelectedTab});
                                              
                 self.PertTransTableUI = uitable(self.Handle,...
                                                'Data',cell(0,7),...
                                                'Units','Normalized',...
                                                'Position',[ChangesTableLabelUI.Position(1)+0.08,ChangesTableLabelUI.Position(2)-0.12,self.BoxSize{2}(1),self.BoxSize{2}(2)],...
                                                'ColumnFormat',{strsplit(num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Regions)),' '),[':',strsplit(num2str(1:numel(self.Gecco.Runs(self.SelectedRun).Chunks)),' ')]},...
                                                'ColumnEditable',[true,true,true,true,true,true,true,true],...
                                                'ColumnName',{'Region','Chunk','Type','Group','Parameter','Depth','Change To'},...
                                                'Tag','PertTransTable',...
                                                'CellSelectionCallback',@self.UpdateSelectedChange,...
                                                'CellEditCallback',@self.UpdatePertTransTable,...
                                                'ColumnWidth',{40,40,70,100,40,200},...
                                                'Parent',self.RunTabHandles{self.SelectedTab});
                                            
                self.ChangePertTransTable();

                %% Log Box
                self.LogBoxUI = uicontrol('Style','edit',...
                                          'Units','Normalized',...
                                          'Position',[0.58,0.30,0.4,0.175],...
                                          'String',self.LogMessages{self.SelectedRun} ,...
                                          'HorizontalAlignment','Left',...
                                          'Max',1000,...
                                          'Parent',self.RunTabHandles{self.SelectedTab});

                %% Buttons
                AddRegionBoxUI = uicontrol('Style','pushbutton',...
                                           'String','Add Region',...
                                           'Units','Normalized',...
                                           'Position',[0.1,0.38,0.08,0.0874],...
                                           'Callback',@self.AddRegionCallback,...
                                           'Parent',self.RunTabHandles{self.SelectedTab});
                RemoveRegionBoxUI = uicontrol('Style','pushbutton',...
                                              'String','Remove Region',...
                                              'Units','Normalized',...
                                              'Position',AddRegionBoxUI.Position+[0,-self.ButtonSpacing(1),0,0],...
                                              'Callback',@self.RemoveRegionCallback,...
                                              'Parent',self.RunTabHandles{self.SelectedTab});
                LoadAllBoxUI = uicontrol('Style','pushbutton',...
                                         'String','Load All',...
                                         'Units','Normalized',...
                                         'Position',AddRegionBoxUI.Position+[self.ButtonSpacing(2),0,0,0],...
                                         'Callback',@self.FullCopyWrapper,...
                                         'Parent',self.RunTabHandles{self.SelectedTab});
                LoadDataBoxUI = uicontrol('Style','pushbutton',...
                                         'String','Load Data',...
                                         'Units','Normalized',...
                                         'Position',AddRegionBoxUI.Position+[self.ButtonSpacing(2),-self.ButtonSpacing(1),0,0],...
                                         'Callback',@self.LoadDataIntoModel,...
                                         'Parent',self.RunTabHandles{self.SelectedTab});
                SpareButton{1} = uicontrol('Style','pushbutton',...
                                                     'String','Spare',...
                                                     'Units','Normalized',...
                                                     'Position',AddRegionBoxUI.Position+([2*self.ButtonSpacing(2),0,0,0]),...
                                                     'Callback',@self.XXX,...
                                                     'Parent',self.RunTabHandles{self.SelectedTab});        
                RunBoxUI = uicontrol('Style','pushbutton',...
                                     'String','Run Model',...
                                     'Units','Normalized',...
                                     'Position',AddRegionBoxUI.Position+([2*self.ButtonSpacing(2),-self.ButtonSpacing(1),0,0]),...
                                     'Callback',@self.RunModel,...
                                     'Parent',self.RunTabHandles{self.SelectedTab});
                SpareButton{2} = uicontrol('Style','pushbutton',...
                                        'String','Spare',...
                                        'Units','Normalized',...
                                        'Position',AddRegionBoxUI.Position+([3*self.ButtonSpacing(2),0,0,0]),...
                                        'Callback',@self.XXX,...
                                        'Parent',self.RunTabHandles{self.SelectedTab});
                SpareButton{3} = uicontrol('Style','pushbutton',...
                                         'String','Spare',...
                                         'Units','Normalized',...
                                         'Position',AddRegionBoxUI.Position+([3*self.ButtonSpacing(2),-self.ButtonSpacing(1),0,0]),...
                                         'Parent',self.RunTabHandles{self.SelectedTab});      
            %% Colour box
            self.ColourBox = uicontrol('Style','text',...
                                       'Units','Normalized',...
                                       'Position',[0.5,0.3,0.05625,0.1],...
                                       'BackgroundColor',[0.6,0.2,0.2],...
                                       'Parent',self.RunTabHandles{self.SelectedTab});
        
        end
        
        function ConstTableData = GetConstTableData(self);
%             Split_Const_String = strsplit(self.ConstSelectorUI.String{self.ConstSelectorUI.Value},'.');
%             if numel(Split_Const_String)==1;
                ConstTableData = horzcat(self.Gecco.Runs(1).Regions(:).Conditions.Constants.(self.ConstGroupSelectorUI.String{self.ConstGroupSelectorUI.Value}).(self.ConstSelectorUI.String{self.ConstSelectorUI.Value}));
%             elseif numel(Split_Const_String)==2;
%                 ConstTableData = horzcat(self.Gecco.Runs(1).Regions(:).Conditions.Constants.(Split_Const_String{1}).(Split_Const_String{2}));
%             elseif numel(Split_Const_String)==3;
%                 ConstTableData = horzcat(self.Gecco.Runs(1).Regions(:).Conditions.Constants.(Split_Const_String{1}).(Split_Const_String{2}).(Split_Const_String{3}));
%             elseif numel(Split_Const_String)==4;
%                 ConstTableData = horzcat(self.Gecco.Runs(1).Regions(:).Conditions.Constants.(Split_Const_String{1}).(Split_Const_String{2}).(Split_Const_String{3}).(Split_Const_String{4}));
%             end
        end
        %%
        function SelectPlot(self,~,~);
            self.RecreateSubplots();
            if self.SubplotIndex==1;
                subplot(self.s{1});
                p{1} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Atmosphere_CO2*1e6,'Color',self.Colours.black);
                ylabel({'CO_2','(ppm)'});
                
                subplot(self.s{2});
                p{2} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Algae,'Color',self.Colours.green);
                ylabel({'Algae','(mol/m^3)'});
                
                subplot(self.s{3});
                p{3} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Phosphate(1,:),'Color',self.Colours.blue);
                hold on
                plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Phosphate(2,:),'Color',self.Colours.darkblue);
                hold off
                ylabel({'Phosphate','(mol/m^3)'});
                
                subplot(self.s{4});
                p{4} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.DIC(1,:),'Color',self.Colours.blue);
                hold on
                plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.DIC(2,:),'Color',self.Colours.darkblue);
                hold off
                ylabel({'DIC','(mol/m^3)'});
                
                subplot(self.s{5});
                p{5} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Alkalinity(1,:),'Color',self.Colours.blue);
                hold on
                plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Alkalinity(2,:),'Color',self.Colours.darkblue);
                hold off
                ylabel({'Alkalinity','(mol/m^3)'});
                
                xlabel('Time (yr)');
                set([self.s{1:4}],'XTick',[]);
                linkaxes([self.s{1:5}],'x');
                xlim([0,max(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time)]);
                
            elseif self.SubplotIndex==2;
                subplot(self.s{1});
                p{1} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Atmosphere_Temperature(1,:)-273.15,'Color',self.Colours.orange);
                hold on
                plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Ocean_Temperature(1,:)-273.15,'Color',self.Colours.blue);
                plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Ocean_Temperature(2,:)-273.15,'Color',self.Colours.darkblue);
                hold off
                ylabel({'Temperature','(^{\circ}C)'});
                
                subplot(self.s{2});
                p{2} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Radiation);
                ylabel({'Radiation','(W/m^2)'});
                
                subplot(self.s{3});
                p{3} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Silicate,'Color',self.Colours.yellow);
                ylabel({'Rock','(mol)'});
                
                subplot(self.s{4});
                Silicate_Weathering_Fraction = self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Silicate_Weathering_Fraction;
                Carbonate_Weathering_Fraction = self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Carbonate_Weathering_Fraction;
                p{4} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,Silicate_Weathering_Fraction);
                hold on
                plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,Carbonate_Weathering_Fraction);
                ylabel({'Weathering',' Fraction',' '});
                hold off
                subplot(self.s{5});
                Silicate_Weathering = Silicate_Weathering_Fraction.*self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Silicate.*self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Conditions.Constants.Weathering.Silicate_Weatherability;
%                 Carbonate_Weathering = Carbonate_Weathering_Fraction.*self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Carbonate.*self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Conditions.Constants.Weathering.Carbonate_Weatherability;
                Carbonate_Weathering = self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Carbonate_Exposed.*Carbonate_Weathering_Fraction.*self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Conditions.Presents.Weathering.Carbonate_Weatherability;
                
                Rivers = (2*(Silicate_Weathering+Carbonate_Weathering))/self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Conditions.Constants.Architecture.Riverine_Volume;
                p{5} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,Rivers);
                ylabel({'Rivers','(mol)'});
                
                xlabel('Time (yr)');
                set([self.s{1:4}],'XTick',[]);
                linkaxes([self.s{1:5}],'x');
                xlim([0,max(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time)]);
            elseif self.SubplotIndex==3;
                subplot(self.s{1});
                p{1} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Ice,'Color',self.Colours.cyan);
                ylabel({'Ice Mass','(mol)'});
                
                subplot(self.s{2});
                p{2} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Sea_Level);
                ylabel({'Sea Level','(m)'}); 
                
                subplot(self.s{3});
                p{3} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Snow_Line,'Color',self.Colours.darkgrey);
                ylabel({'Snow Line','(m)'});
                
                subplot(self.s{4});
                p{4} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Conditions.Presents.Carbon.PIC_Burial(1,:),'Color',self.Colours.cyan);
                hold on
                p{5} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Conditions.Presents.Carbon.PIC_Burial(2,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.blue);
                hold off
                ylabel({'PIC Burial','(fraction)'});
                ylim([0,1]);
                
                set([self.s{1:3}],'XTick',[]);
                linkaxes([self.s{1:4}],'x');
                
                xlabel('Time (yr)');
                xlim([0,max(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time)]);
            elseif self.SubplotIndex==4;
                subplot(self.s{1});
                p{1} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Lysocline+self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Sea_Level,'Color',self.Colours.blue);
                ylabel({'Lysocline','(m)'});
                set(gca,'YDir','Reverse');
                xlim([min(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time),max(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time)]);
                ylim([min(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Lysocline)-500,max(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Lysocline)+500]);
                
                subplot(self.s{2});
                p{2} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Conditions.Constants.Architecture.Hypsometric_Bin_Midpoints,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Seafloor);
                ylabel({'Carbonate',' Distribution','(mol)'});
                set(gca,'XDir','Reverse');
                
                subplot(self.s{3});
                p{3} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Conditions.Constants.Outgassing.Temporal_Resolution*(1:numel(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Outgassing)),self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Outgassing,'Color',self.Colours.red);
                ylabel({'Outgassing','(mol)'});
                
                subplot(self.s{4});
                p{4} = plot(self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Time,self.Gecco.Runs(self.PlotRunSelectorUI.Value).Regions(1).Outputs.Carbonate_Total);
                ylabel({'Seafloor Total','(mol)'});
            end
        end
        function SetSaveFlag(self,src,event);
            if strcmp(src.Tag,"SaveToSameFileTickbox");
                self.Gecco.SaveToSameFileFlag = event.Source.Value;
            elseif strcmp(src.Tag,"SaveByRunsTickbox");
                self.Gecco.SaveToRunFilesFlag = event.Source.Value;
            elseif strcmp(src.Tag,"SplashShouldSaveTickboxUI");
                self.Gecco.ShouldSaveFlag = event.Source.Value;
            else
                self.UpdateLogBox("Something went wrong setting a save flag");
            end
        end
        function SelectiveClear(self,src,event);
            if strcmp(src.String,"Output Filepath");
                src.Enable = 'On';
                src.String = "";
                src.ForegroundColor = self.Colours.black;
                uicontrol(src);
            elseif strcmp(src.String,"");
                src.Enable = 'Inactive';
                src.ForegroundColor = self.Colours.grey;
                if strcmp(src.Tag,"SplashInputFile") || strcmp(src.Tag,"InputFile");
                   src.String = "Input File";
                elseif strcmp(src.Tag,"SplashOutputFilepath") || strcmp(src.Tag,"OutputFilepath");
                    src.String = "Output Filepath";
                elseif strcmp(src.Tag,"SplashOutputFilename") || strcmp(src.Tag,"OutputFilename");
                    src.String = "Output Filename";
                end
            else
                src.Enable = 'On';
                src.ForegroundColor = self.Colours.black;
                uicontrol(src);
            end
        end
        % Function to switch plot page onwards
        function PlotRight(self,src,event);
            % Wrap if at final page
            if self.SubplotIndex==4;
                self.SubplotIndex=1;
            else
                self.SubplotIndex=self.SubplotIndex+1;
            end
            self.SelectPlot;
        end
        % Function to switch plot page backwards
        function PlotLeft(self,src,event);
            % Wrap if at first page
            if self.SubplotIndex==1;
                self.SubplotIndex=4;
            else
                self.SubplotIndex=self.SubplotIndex-1;
            end
            self.SelectPlot;
        end
        % Creates the right number of subplots for the page
        function RecreateSubplots(self,src,event);
            if self.SubplotIndex == 1 || self.SubplotIndex==2;
                self.s = cell(1,5);
                for n = 1:5;
                    self.s{n} = subplot(5,1,n,'Parent',self.PlotTabHandle);
                end
            else
                if numel(self.s)>4;
                    delete(self.s{5});
                end
                if self.SubplotIndex == 4;
                    delete(self.s{1});
                    delete(self.s{2});
                    delete(self.s{3});
                    delete(self.s{4});
                end
                self.s = cell(1,4);
                for n = 1:4;
                    self.s{n} = subplot(4,1,n,'Parent',self.PlotTabHandle);
                end
            end
        end
    end
end
