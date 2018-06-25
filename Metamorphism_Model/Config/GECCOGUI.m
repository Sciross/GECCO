classdef GECCOGUI < handle;
    properties
        Handle
        Size
        Model
        Runs
        OutputFile
    end
    properties (Hidden=true);
        RunTable
        RunTableUI
        InitSelectorUI
        InitialTableUI
        LogMessages
        LogBoxUI
        InstalledModels
        CoreUI
        SolverUI
        ModelUI
        AvailableCores
        ConstSelectorUI
        ConstTableUI
        VarTableUI
        ModelOnPath
        SelectedRun
        SelectedChunk
        PertTableUI
        FilepathUI
        FilenameUI
        FileInputUI
        SelectedPert
        FilenameWarningUI
        RunIndices
        VarIndices
        OutputFilepath
        InputFilepath
        OutputFilename
        ChunkEnds
        RunMatrix
        PertMatrix
        ConstMatrix
        VarMatrix
        InitMatrix
        ValidatedFlag = 0;
        PlotRunSelectorUI
        s
        ColourBox
    end
    methods
        function self = GECCOGUI(FileInput);
            CurrentDir = dir('.');
            CurrentDirRight = sum(strcmp(vertcat({CurrentDir(:).name}),'GECCOGUI.m'));
            if ~CurrentDirRight;
                error('Incorrect folder for initialisation - make sure GECCOGUI is in the current directory');
            end
            
            if nargin==0;
                FileInput = 'none';
            end
            
            if ~strcmp(FileInput,'-headless');
                self.Handle = figure('Position',[100,100,1100,600]); 
                self.Size = get(self.Handle,'Position');
                self.LogMessages = {'Begun'};
                addpath('./../../Solvers/');

                %% Tabbing
                TabGroupHandle = uitabgroup('Parent',self.Handle,...
                                            'SelectionChangedFcn',@self.TabChangeCallback);
                Tab1Handle = uitab('Parent',TabGroupHandle,'Title','Run Model');
                Tab2Handle = uitab('Parent',TabGroupHandle,'Title','Plot Data');

                %% Filepath
                FileInputLabelUI = uicontrol('Style','text',...
                                             'Units','Normalized',...
                                             'Position',[0.017,0.907,0.091,0.087],...
                                             'HorizontalAlignment','left',...
                                             'String','Input Filepath',...
                                             'Parent',Tab1Handle);
                self.FileInputUI = uicontrol('Style','edit',...
                                             'Units','Normalized',...
                                             'Position',[0.0173,0.9336,0.4106,0.035],...
                                             'HorizontalAlignment','left',...
                                             'Parent',Tab1Handle);
                FileInputBrowseButton = uicontrol('Style','Pushbutton',...
                                                  'String','Browse',...
                                                  'Units','Normalized',...
                                                  'Position',[0.437,0.9336,0.046,0.035],...
                                                  'Callback',@self.SetInputFilepath,...
                                                  'Parent',Tab1Handle);
                FilepathLabelUI = uicontrol('Style','text',...
                                            'Units','Normalized',...
                                            'Position',[0.017,0.837,0.091,0.087],...
                                            'HorizontalAlignment','left',...
                                            'String','Output Filepath',...
                                            'Parent',Tab1Handle);
                self.FilepathUI = uicontrol('Style','edit',...
                                            'Units','Normalized',...
                                            'Position',[0.0173,0.865,0.4106,0.035],...
                                            'HorizontalAlignment','left',...
                                            'Parent',Tab1Handle);
                FilepathBrowseButton = uicontrol('Style','Pushbutton',...
                                                 'String','Browse',...
                                                 'Units','Normalized',...
                                                 'Position',[0.437,0.865,0.046,0.035],...
                                                 'Callback',@self.SetOutputFilepath,...
                                                 'Parent',Tab1Handle);
                FilenameLabelUI = uicontrol('Style','text',...
                                            'Units','Normalized',...
                                            'Position',[0.017,0.75,0.091,0.087],...
                                            'HorizontalAlignment','left',...
                                            'String','Filename',...
                                            'Parent',Tab1Handle);
                self.FilenameUI = uicontrol('Style','edit',...
                                            'Units','Normalized',...
                                            'Position',[0.063,0.8024,0.3650,0.035],...
                                            'HorizontalAlignment','Left',...
                                            'Callback',@self.SetOutputFileCallback,...
                                            'Parent',Tab1Handle);
                self.FilenameWarningUI = uicontrol('Style','text',...
                                                   'Units','Normalized',...
                                                   'Position',[0.4370,0.8024,0.0912,0.035],...
                                                   'HorizontalAlignment','left',...
                                                   'String',' ',...
                                                   'Parent',Tab1Handle);
                %% Model, Core + Solver     
                ModelLabelUI = uicontrol('Style','text',...
                                         'Units','Normalized',...
                                         'Position',[0.0173,0.7675,0.1369,0.035],...
                                         'String','Model',...
                                         'HorizontalAlignment','Left',...
                                         'Parent',Tab1Handle);
                self.ModelUI = uicontrol('Style','popupmenu',...
                                         'String','-',...
                                         'Units','Normalized',...
                                         'Position',[0.0173,0.7325,0.1369,0.035],...
                                         'Callback',@self.ChangeModelCallback,...
                                         'CreateFcn',@self.GetInstalledModels,...
                                         'Parent',Tab1Handle);
                ModelInstantiationButton = uicontrol('Style','pushbutton',...
                                                     'String','Instantiate Model',...
                                                     'Units','Normalized',...
                                                     'Position',[0.3367,0.6976,0.0912,0.0874],...
                                                     'Callback',@self.InstantiateModel,...
                                                     'Parent',Tab1Handle);

                CoreLabelUI = uicontrol('Style','text',...
                                        'Units','Normalized',...
                                        'Position',[0.0173,0.6976,0.1369,0.035],...
                                        'String','Core',...
                                        'HorizontalAlignment','Left',...
                                        'Parent',Tab1Handle);
                self.CoreUI = uicontrol('Style','popupmenu',...
                                        'String',{'-'},...
                                        'Units','Normalized',...
                                        'Position',[0.0173,0.6626,0.1369,0.035],...
                                        'CreateFcn',@self.GetAvailableCores,...
                                        'Callback',@self.SelectCoreCallback,...
                                        'Parent',Tab1Handle);

                SolverLabelUI = uicontrol('Style','text',...
                                          'Position',[0.0173,0.6276,0.1369,0.035],...
                                          'Units','Normalized',...
                                          'String','Solver',...
                                          'HorizontalAlignment','Left',...
                                          'Parent',Tab1Handle);
                self.SolverUI = uicontrol('Style','popupmenu',...
                                          'String',{'MySolver_1_Implicit_Trial'},...
                                          'Units','Normalized',...
                                          'Position',[0.0173,0.5927,0.1369,0.035],...
                                          'Parent',Tab1Handle);

                %% Run Table
                RunTableLabelUI = uicontrol('Style','text',...
                                            'Units','Normalized',...
                                            'Position',[0.5009,0.9073,0.1369,0.0874],...
                                            'String','Run Details',...
                                            'HorizontalAlignment','Left',...
                                            'Parent',Tab1Handle);
                self.RunTableUI = uitable(self.Handle,...
                                          'Data',self.RunTableUI,...
                                          'Units','Normalized',...
                                          'Position',[0.5009,0.75,0.4106,0.2098],...
                                          'CellSelectionCallback',@self.UpdateRunIndices,...
                                          'CellEditCallback',@self.RunTableEditCallback,...
                                          'ColumnName',{'Run','Chunk','Start','End','Step','Start','End','Step'},...
                                          'ColumnWidth',{40,40,60,60,40,60,60,40},...
                                          'ColumnEditable',[true,true,true,true,true,true,true,true],...
                                          'Parent',Tab1Handle);
                RunTableAddButtonUI = uicontrol('Style','pushbutton',...
                                                'Units','Normalized',...
                                                'Position',[0.9206,0.9073,0.073,0.0524],...
                                                'String','Add Run',...
                                                'Callback',@self.AddRunCallback,...
                                                'Tag','RunTableAddButton',...
                                                'Parent',Tab1Handle);
                ChunkTableAddButtonUI = uicontrol('Style','pushbutton',...
                                                  'Units','Normalized',...
                                                  'Position',[0.9206,0.8549,0.073,0.0524],...
                                                  'String','Add Chunk',...
                                                  'Callback',@self.AddChunkCallback,...
                                                  'Parent',Tab1Handle);
                RunTableRmButtonUI = uicontrol('Style','pushbutton',...
                                               'Units','Normalized',...
                                               'Position',[0.9206,0.8024,0.073,0.0524],...
                                               'String','Remove Entry',...
                                               'Callback',@self.RunTableRmEntry,...
                                               'Parent',Tab1Handle);
                RunLoadButtonUI = uicontrol('Style','pushbutton',...
                                            'Units','Normalized',...
                                            'Position',[0.9206,0.75,0.073,0.0524],...
                                            'String','Load',...
                                            'Callback',@self.LoadRuns,...
                                            'Parent',Tab1Handle);
                %% Initial Table
                InitialTableLabelUI = uicontrol('Style','text',...
                                                'Units','Normalized',...
                                                'Position',[0.0173,0.4703,0.1369,0.0874],...
                                                'String','Initial Conditions',...
                                                'HorizontalAlignment','Left',...
                                                'Parent',Tab1Handle);
                self.InitSelectorUI = uicontrol('Style','popupmenu',...
                                                'Units','Normalized',...
                                                'Position',[0.0903,0.4703,0.1369,0.0874],...
                                                'String','-',...
                                                'Callback',@self.UpdateInitialTable,...
                                                'Parent',Tab1Handle);
                self.InitialTableUI = uitable(self.Handle,...
                                              'Data',self.InitialTableUI,...
                                              'Units','Normalized',...
                                              'Position',[0.0173,0.3654,0.4106,0.1399],...
                                              'ColumnEditable',[true],...
                                              'CellEditCallback',@self.InitTableEditCallback,...
                                              'Parent',Tab1Handle);
                InitLoadButtonUI = uicontrol('Style','pushbutton',...
                                             'Units','Normalized',...
                                             'Position',[0.4370,0.4528,0.0547,0.0524],...
                                             'String','Load',...
                                             'Callback',@self.LoadInits,...
                                             'Parent',Tab1Handle);
                InitLoadFinalButtonUI = uicontrol('Style','pushbutton',...
                                                  'Units','Normalized',...
                                                  'Position',[0.437,0.3829,0.0547,0.0524],...
                                                  'String','Load Final',...
                                                  'Callback',@self.LoadFinal,...
                                                  'Parent',Tab1Handle);
                %% Constant Table
                ConstTableLabelUI = uicontrol('Style','text',...
                                              'Units','Normalized',...
                                              'Position',[0.0173,0.2605,0.1369,0.0874],...
                                              'String','Constants',...
                                              'HorizontalAlignment','Left',...
                                              'Parent',Tab1Handle);
                self.ConstSelectorUI = uicontrol('Style','popupmenu',...
                                                 'Units','Normalized',...
                                                 'Position',[0.0903,0.2605,0.1369,0.0874],...
                                                 'String','-',...
                                                 'Callback',@self.UpdateConstTable,...
                                                 'Parent',Tab1Handle);
                self.ConstTableUI = uitable(self.Handle,...
                                            'Data',self.ConstTableUI,...
                                            'Units','Normalized',...
                                            'Position',[0.0173,0.1206,0.4106,0.1748],...
                                            'ColumnEditable',[true,true,true,true,true,true,true],...
                                            'ColumnName',{'Run 1'},...
                                            'CellEditCallback',@self.ConstTableEditCallback,...
                                             'Parent',Tab1Handle);
                ConstLoadButtonUI = uicontrol('Style','pushbutton',...
                                              'Units','Normalized',...
                                              'Position',[0.4370,0.2430,0.0547,0.0524],...
                                              'String','Load',...
                                              'Callback',@self.LoadConstsCallback,...
                                              'Parent',Tab1Handle);
                %% Perturbation Table
                PertTableLabelUI = uicontrol('Style','text',...
                                             'Units','Normalized',...
                                             'Position',[0.5009,0.6451,0.1369,0.0874],...
                                             'String','Perturbations',...
                                             'HorizontalAlignment','Left',...
                                             'Parent',Tab1Handle);
                self.PertTableUI = uitable(self.Handle,...
                                           'Data',cell(0,5),...
                                           'Units','Normalized',...
                                           'Position',[0.5009,0.5227,0.4106,0.1748],...
                                           'ColumnEditable',[true,true,true,true,true],...
                                           'ColumnName',{'Run','Chunk','Parameter','Depth','Change To'},...
                                           'CellEditCallback',@self.UpdatePertTableDefinition,...
                                           'CellSelectionCallback',@self.UpdateSelectedPert,...
                                           'Tag','PertTable',...
                                           'ColumnWidth',{40,40,100,40,200},...
                                           'Parent',Tab1Handle);
                AddPertButtonUI = uicontrol('Style','pushbutton',...
                                            'Units','Normalized',...
                                            'Position',[0.9206,0.6451,0.0274,0.0524],...
                                            'String','+',...
                                            'Callback',@self.AddPerturbation,...
                                            'Parent',Tab1Handle);
                RmPertButtonUI = uicontrol('Style','pushbutton',...
                                           'Units','Normalized',...
                                           'Position',[0.9206,0.5926,0.0274,0.0524],...
                                           'String','-',...
                                           'Callback',@self.RemovePerturbation,...
                                           'Parent',Tab1Handle);
                PertLoadButtonUI = uicontrol('Style','pushbutton',...
                                             'Units','Normalized',...
                                             'Position',[0.9206,0.5402,0.0547,0.0524],...
                                             'String','Load',...
                                             'Callback',@self.LoadPerts,...
                                             'Parent',Tab1Handle);
                %% Variable Table                 
                VarTableLabelUI = uicontrol('Style','text',...
                                            'Units','Normalized',...
                                            'Position',[0.5009,0.4178,0.1369,0.0874],...
                                            'String','Variables',...
                                            'HorizontalAlignment','Left',...
                                            'Parent',Tab1Handle);
                self.VarTableUI = uitable(self.Handle,...
                                          'Data',cell(0,3),...
                                          'Units','Normalized',...
                                          'Position',[0.5009,0.2954,0.4106,0.1748],...
                                          'Tag','VarTable',...
                                          'ColumnName',{'Parameter','Depth','Change To'},...
                                          'CreateFcn',@self.GetVariables,...
                                          'CellSelectionCallback',@self.UpdateSelectedVar,...
                                          'CellEditCallback',@self.UpdateVariableTable,...
                                          'ColumnWidth',{100,40,200},...
                                          'Parent',Tab1Handle);
                AddVarButtonUI = uicontrol('Style','pushbutton',...
                                           'Units','Normalized',...
                                           'Position',[0.9206,0.4178,0.0274,0.0524],...
                                           'String','+',...
                                           'Callback',@self.AddVariable,...
                                           'Parent',Tab1Handle);
                RmVarButtonUI = uicontrol('Style','pushbutton',...
                                           'Units','Normalized',...
                                           'Position',[0.9206,0.3654,0.0274,0.0524],...
                                           'String','-',...
                                           'Callback',@self.RmVariable,...
                                           'Parent',Tab1Handle);
                VarLoadButtonUI = uicontrol('Style','pushbutton',...
                                            'Units','Normalized',...
                                            'Position',[0.9206,0.3129,0.0547,0.0524],...
                                            'String','Load',...
                                            'Callback',@self.LoadVars,...
                                            'Parent',Tab1Handle);

                %% Log Box
                self.LogBoxUI = uicontrol('Style','edit',...
                                          'Units','Normalized',...
                                          'Position',[0.5,0.1,0.4106,0.1486],...
                                          'String',self.LogMessages,...
                                          'HorizontalAlignment','Left',...
                                          'Max',1000,...
                                          'Parent',Tab1Handle);

                %% Finalisation
                RunBoxUI = uicontrol('Style','pushbutton',...
                                     'String','Run Model',...
                                     'Units','Normalized',...
                                     'Position',[0.3367,0.6101,0.0912,0.0874],...
                                     'Callback',@self.RunModel,...
                                     'Parent',Tab1Handle);

                %% Loading
                LoadAllBoxUI = uicontrol('Style','pushbutton',...
                                         'String','Load All',...
                                         'Units','Normalized',...
                                         'Position',[0.2272,0.6101,0.0912,0.0874],...
                                         'Callback',@self.FullCopyWrapper,...
                                         'Parent',Tab1Handle);
                LoadDataBoxUI = uicontrol('Style','pushbutton',...
                                         'String','Load Data',...
                                         'Units','Normalized',...
                                         'Position',[0.2272,0.701,0.0912,0.0874],...
                                         'Callback',@self.LoadDataIntoModel,...
                                         'Parent',Tab1Handle); 

                %% Plot Control
                self.PlotRunSelectorUI = uicontrol('Style','popupmenu',...
                                                   'Units','Normalized',...
                                                   'Position',[0.0173,0.9423,0.1369,0.035],...
                                                   'String','-',...
                                                   'Parent',Tab2Handle,...
                                                   'Callback',@self.SelectPlot);

                self.s{1} = subplot(5,1,1,'Parent',Tab2Handle);
                self.s{2} = subplot(5,1,2,'Parent',Tab2Handle);
                self.s{3} = subplot(5,1,3,'Parent',Tab2Handle);
                self.s{4} = subplot(5,1,4,'Parent',Tab2Handle);
                self.s{5} = subplot(5,1,5,'Parent',Tab2Handle);

                %% Colour box
                self.ColourBox = uicontrol('Style','text',...
                                           'Units','Normalized',...
                                           'Position',[0.92,0.13,0.05625,0.1],...
                                           'BackgroundColor',[0.6,0.2,0.2]);
            end
            %% Input
            if ~strcmp(FileInput,'none') && ~strcmp(FileInput,'-headless');
                self.FullCopy(FileInput);
            end
        end
        %% Tab Change Callback
        function TabChangeCallback(self,src,event);
            if strcmp(event.NewValue.Title,'Plot Data');
                if ~isempty(self.Model);
                    if ~isempty(self.Model.Data);
                        subplot(self.s{1});
                        p{1} = plot(self.Model.Time(:,1,1),self.Model.Data(:,1)*1000000);
                        ylabel({'CO_2','(ppm)'});
                        
                        subplot(self.s{2});
                        p{2} = plot(self.Model.Time(:,1,1),self.Model.Data(:,2,1));
                        ylabel({'Algae','(mol/m^3)'});
                        
                        subplot(self.s{3});
                        p{3} = plot(self.Model.Time(:,1,1),self.Model.Data(:,3:4,1));
                        ylabel({'Phosphate','(mol/m^3)'});
                        
                        subplot(self.s{4});
                        p{4} = plot(self.Model.Time(:,1,1),self.Model.Data(:,5:6,1));
                        ylabel({'DIC','(mol/m^3)'});
                        
                        subplot(self.s{5});
                        p{5} = plot(self.Model.Time(:,1,1),self.Model.Data(:,7:8,1));
                        ylabel({'Alkalinity','(mol/m^3)'});
                        
                        xlabel('Datapoint (number)');
                        set([self.s{1:4}],'XTick',[]);
                        linkaxes([self.s{1:5}],'x');
                    end
                end
            end
        end
        function SelectPlot(self,src,event);
            subplot(self.s{1});
            p{1} = plot(self.Model.Time(:,1,self.PlotRunSelectorUI.Value),self.Model.Data(:,1,self.PlotRunSelectorUI.Value)*1000000);
            ylabel({'CO_2','(ppm)'});
            
            subplot(self.s{2});
            p{2} = plot(self.Model.Time(:,1,self.PlotRunSelectorUI.Value),self.Model.Data(:,2,self.PlotRunSelectorUI.Value));
            ylabel({'Algae','(mol/m^3)'});
            
            subplot(self.s{3});
            p{3} = plot(self.Model.Time(:,1,1),self.Model.Data(:,3:4,1));
            ylabel({'Phosphate','(mol/m^3)'});
            
            subplot(self.s{4});
            p{4} = plot(self.Model.Time(:,1,1),self.Model.Data(:,5:6,1));
            ylabel({'DIC','(mol/m^3)'});
            
            subplot(self.s{5});
            p{5} = plot(self.Model.Time(:,1,1),self.Model.Data(:,7:8,1));
            ylabel({'Alkalinity','(mol/m^3)'});
                    
            xlabel('Datapoint (number)');
            set([self.s{1:4}],'XTick',[]);
            linkaxes([self.s{1:5}],'x');
%             xlim([0,size(self.Model.Data,1)]);
        end
        %% Filepath Callbacks
        % Open browse window for filepath
        function SetOutputFilepath(self,src,event);
            if isempty(self.FilepathUI.String);
                self.OutputFilepath = uigetdir('./../../../Results');
            else
                self.OutputFilepath = uigetdir(self.FilepathUI.String);
            end
            if self.OutputFilepath~=0;
                self.FilepathUI.String = self.OutputFilepath;
            end
        end
        function SetOutputFilename(self,src,event);
            self.OutputFilename = self.FilenameUI.String;
        end
        function SetInputFilepath(self,src,event);
            [InputFilename,InputFilepath] = uigetfile('*.nc');
            if InputFilename~=0;
                self.InputFilepath = [InputFilepath,InputFilename];
                self.FileInputUI.String = self.InputFilepath;
                
                Model = ncreadatt(self.FileInputUI.String,'/','Model');
                Core = ncreadatt(self.FileInputUI.String,'/','Core');
                Solver = ncreadatt(self.FileInputUI.String,'/','Solver');
                
                self.ModelUI.Value = find(strcmp(self.ModelUI.String,Model));
                self.GetAvailableCores;
                self.CoreUI.Value = find(strcmp(self.CoreUI.String,Core));
                self.SolverUI.Value = find(strcmp(self.SolverUI.String,Solver));
            end
            
        end
        function SetOutputFileCallback(self,src,event);
            self.ValidateFilename(src,event);
            self.SetOutputFilename(src,event);
            self.CheckFileExists(src,event);
        end
        % Check file exists and produce relevant output
        function CheckFileExists(self,src,event);
            if ~isempty(self.FilepathUI.String);
                FullFile = [self.FilepathUI.String,'\',self.FilenameUI.String];
                Exists = exist(FullFile,'file');
                if Exists;
                    set(self.FilenameWarningUI,'String','File exists',...
                                               'ForegroundColor','red');
                else
                    set(self.FilenameWarningUI,'String','Go on',...
                                               'ForegroundColor','green');
                end
            end
        end
        function ValidateFilename(self,src,event);
            SplitFilename = strsplit(src.String,'.');
            if numel(SplitFilename)==1;
                src.String = [src.String,'.nc'];
                self.UpdateLogBox('Warning: File extension .nc added');
            else
                Ending = SplitFilename{end};
                if ~strcmp(Ending,'nc');
                    src.String = [SplitFilename{1:end-1},'.nc'];
                    self.UpdateLogBox('Warning: File extension changed to .nc');
                end
            end
        end
        %% Model Callbacks
        % Changes path to correct model
        function ChangeModelCallback(self,src,event);
           self.RmModelFromPath(src,event);
           self.AddModelToPath(src,event);
           self.GetAvailableCores(src,event);
        end
        % Adds model to path
        function AddModelToPath(self,src,event)
            addpath(genpath(['./../../',src.String{src.Value}]));
            self.ModelOnPath = src.String{src.Value};
        end
        % Removes model from path
        function RmModelFromPath(self,src,event);
            if ~isempty(self.ModelOnPath);
                rmpath(genpath(['./../../',self.ModelOnPath]));
            end
        end
        % Instantiates a plain model
        function InstantiateModel(self,src,event);
            if self.ModelUI.Value==1;
                self.UpdateLogBox('Choose a model first');
            else
                self.Model = GECCO();
                % Prints to log box
                self.UpdateLogBox('Model instantiated');
                
                % Sets values of GECCO
                self.Model.ModelFcn = str2func(self.ModelUI.String{self.ModelUI.Value});
                self.Model.CoreFcn = strrep(self.CoreUI.String{self.CoreUI.Value},'.m','');
                self.Model.SolverFcn = str2func(self.SolverUI.String{self.SolverUI.Value});
                
                self.Model.Model = self.ModelUI.String{self.ModelUI.Value};
                self.Model.Core = self.CoreUI.String{self.CoreUI.Value};
                self.Model.Solver = self.SolverUI.String{self.SolverUI.Value};
            end
        end
        % Gets available models
        function GetInstalledModels(self,src,event);
            % Looks for directory contents matching pattern
            DirectoryContentsModelsFull = dir('./../../*_Model*');
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
                AvailableCoresFull = dir(['./../../',self.ModelUI.String{self.ModelUI.Value},'/Core/**/*.m']);
                % Concatenates the names from the struct
                self.AvailableCores = strrep(vertcat({AvailableCoresFull(:).name}),'.m','');
                % Sets the appropriate string
                self.CoreUI.String = self.AvailableCores;
            end
        end
        function SelectCoreCallback(self,src,event);
            self.Model.Core = self.CoreUI.String{self.CoreUI.Value};
            self.Model.CoreFcn = strrep(self.CoreUI.String{self.CoreUI.Value},'.m','');
        end
        %% Run Table Callbacks
        % Store currently selected run
        function UpdateCurrentRun(self,src,event);
            if ~isempty(event.Indices);
                self.SelectedRun = src.Data(event.Indices(1),1);
            end
        end
        % Store currently selected chunk
        function UpdateCurrentChunk(self,src,event);
            if ~isempty(event.Indices);
                self.SelectedChunk = src.Data(event.Indices(1),2);
            end
        end 
        % Store currently selected indices
        function UpdateRunIndices(self,src,event);
            self.UpdateCurrentRun(src,event);
            self.UpdateCurrentChunk(src,event);
            self.RunIndices = event.Indices;
        end
        % Add a run
        function AddRunCallback(self,src,event);
            if ~isempty(self.Model);
                % If empty just instantiate one
                if isempty(self.Runs);
                    self.Runs = Run(Chunk([0,10000,1],[0,10000,10]));
                    self.Model.Conditions = Condition();
                % Otherwise use the inherent method
                else
                    self.Runs = self.Runs.AddRun([0,10000,1],[0,10000,10],self.Model);
                end
                % Then build the table from scratch
                self.RunTableUI.Data = self.BuildRunTable;
                % Update the perturbation table data
                self.UpdatePertTableDefinition(src,event);
                % Update the variable table data
                self.UpdateVariableTable(src,event);
                % Update the initial table titles
                self.ExtendInitTableTitles(src,event);
                % Update the constant table titles
                self.ExtendConstTableTitles(src,event);
                
                PlotStrings = num2str(1:numel(self.Runs));
                PlotCells = strsplit(PlotStrings,' ');
                self.PlotRunSelectorUI.String = PlotCells;
                % Instantiates constant names
                self.ConstSelectorUI.String = fieldnames(self.Model.Conditions.Constant);
                % Instantiates initial names
                self.InitSelectorUI.String = fieldnames(self.Model.Conditions.Initial);
            else
                % Otherwise error out
                self.UpdateLogBox('Error: Instantiate the model first');
            end
        end
        % Add a chunk
        function AddChunkCallback(self,src,event);
            % Error if no run is selected
            if isempty(self.SelectedRun);
                self.UpdateLogBox('Error: No run selected');
            else
                % Otherwise call the inherent method
                self.Runs(self.SelectedRun).AddChunk(Chunk([0,1000,1],[0,1000,10]));
                % Rebuild the table
                self.RunTableUI.Data = self.BuildRunTable;
            end
        end
        % Build a run table
        function RunTable = BuildRunTable(self,src,event);
            % Go through each entry and store relevant info.
            if numel(self.Runs)==0;
                RunTable = [];
            else
                Count = 1;
                for RunIndex = 1:numel(self.Runs);
                    ChunkNumber = numel(self.Runs(RunIndex).Chunks);
                    for ChunkIndex = 1:ChunkNumber;
                        RunTable(Count,1) = RunIndex;
                        RunTable(Count,2) = ChunkIndex;
                        RunTable(Count,3:5) = self.Runs(RunIndex).Chunks(ChunkIndex).TimeIn;
                        RunTable(Count,6:8) = self.Runs(RunIndex).Chunks(ChunkIndex).TimeOut;
                        Count = Count+1;
                    end
                end
            end
        end
        % Remove an entry from the run table
        function RunTableRmEntry(self,src,event);
            % If something is selected
            if ~isempty(self.RunIndices);
                % Remove from GECCO
                self.Runs(self.SelectedRun).Chunks(self.SelectedChunk) = [];
                
                for n = numel(self.Runs):-1:1;
                    if numel(self.Runs(n).Chunks)==0;
                        self.Runs(n) = [];
                    end
                end
                % Rebuild the table
                self.RunTableUI.Data = self.BuildRunTable(src,event);
            else
                % Print to log
                self.UpdateLogBox('Error removing run');         
            end
        end
        function RunTableEditCallback(self,src,event);
            self.Runs(self.SelectedRun).Chunks(self.SelectedChunk).TimeIn = event.Source.Data(event.Indices(1),3:5);
            self.Runs(self.SelectedRun).Chunks(self.SelectedChunk).TimeOut = event.Source.Data(event.Indices(1),6:8);
        end
        function LoadRuns(self,src,event);
            if isempty(self.FileInputUI.String);
                self.SetInputFilepath;
            end
            RunMatrix = ncread(self.FileInputUI.String,'/Replication/Run_Matrix');
            TimeIn = RunMatrix(1,3:5);
            TimeOut = RunMatrix(1,6:8);
            self.Runs = Run(Chunk(TimeIn,TimeOut),self.Model);
            for RunIndex = 2:size(RunMatrix,1);
                TimeIn = RunMatrix(RunIndex,3:5);
                TimeOut = RunMatrix(RunIndex,6:8);
                if RunMatrix(RunIndex,1)==numel(self.Runs);
                    self.Runs(RunMatrix(RunIndex,1)).AddChunk(Chunk(TimeIn,TimeOut));
                else
                    self.Runs = self.Runs.AddRun(TimeIn,TimeOut,self.Model);
                end
            end
            self.RunTableUI.Data = RunMatrix;
        end
        function ValidateRuns(self,src,event);
            for RunIndex = 1:numel(self.Runs);
                for ChunkIndex = 1:numel(self.Runs(RunIndex).Chunks);
                    if ChunkIndex == numel(self.Runs(RunIndex).Chunks);
                        break;
                    else
                        TimeOutEnd = self.Runs(RunIndex).Chunks(ChunkIndex).TimeOut(2);
                        TimeOutStart = self.Runs(RunIndex).Chunks(ChunkIndex+1).TimeOut(1);
                        
                        if TimeOutStart~=TimeOutEnd;
                            self.ValidatedFlag = 0;
                            self.UpdateLogBox(['The chunks in Run ',num2str(RunIndex),' are not consecutive']);
                        end
                    end
                end
            end
        end
        %% Initial Callbacks
        % Updates the constant table definition
        function UpdateInitialTable(self,src,event);
            % On cell change update the 
            Table = horzcat(self.Model.Conditions.Initial(1:end).(src.String{src.Value}));
            self.InitialTableUI.Data = Table;
        end
        function InitTableEditCallback(self,src,event);
            self.Model.Conditions.Initial(event.Indices(2)).(self.InitSelectorUI.String{self.InitSelectorUI.Value})(event.Indices(1),1) = event.NewData;
            self.Model.Conditions.Initial(event.Indices(2)).Conditions = [self.Model.Conditions.Initial(event.Indices(2)).Atmosphere_CO2,self.Model.Conditions.Initial(event.Indices(2)).Algae,self.Model.Conditions.Initial(event.Indices(2)).Phosphate',self.Model.Conditions.Initial(event.Indices(2)).DIC',self.Model.Conditions.Initial(event.Indices(2)).Alkalinity'];
        end
        function ExtendInitTableTitles(self,src,event);
            RunNumber = numel(self.Runs);
            for n = 1:RunNumber;
                CellTitle{n} = ['Run ',num2str(n)];
            end
            self.InitialTableUI.ColumnName = CellTitle;
        end
        function LoadInits(self,src,event);
            if isempty(self.Model);
                self.UpdateLogBox('Please instantiate model first');
            elseif isempty(self.RunTableUI.Data);
                self.UpdateLogBox('No runs to load');
            else
                if isempty(self.FileInputUI.String);
                    self.SetInputFilepath;
                end
                InitMatrix = ncread(self.FileInputUI.String,'/Replication/Initial_Matrix');
                if size(InitMatrix,1)<size(self.RunTableUI.Data,1);
                    self.UpdateLogBox('More runs than initial conditions');
                    for RunIndex = 1:size(self.InitMatrix,1);
                        self.Model.Conditions.Initial(RunIndex).Conditions = InitMatrix(RunIndex,:);
                        self.Model.Conditions.Deal(RunIndex);
                    end 
                elseif size(InitMatrix,1)==size(self.RunTableUI.Data,1);
                    for RunIndex = 1:size(self.RunTableUI.Data,1);
                        self.Model.Conditions.Initial(RunIndex).Conditions = InitMatrix(RunIndex,:);
                        self.Model.Conditions.Deal(RunIndex);
                    end
                elseif size(InitMatrix,1)>size(self.RunTableUI.Data,1);
                     self.UpdateLogBox('Fewer runs than initial conditions');
                    for RunIndex = 1:size(self.RunTableUI.Data,1);
                        self.Model.Conditions.Initial(RunIndex).Conditions = InitMatrix(RunIndex,:);
                        self.Model.Conditions.Deal(RunIndex);
                    end
                end
                % Update the initial table titles
                if ~exist('src','var');
                    self.ExtendInitTableTitles;
%                     src = 1;
%                     event = 1;
                else                    
                    self.ExtendInitTableTitles(src,event);
                end
            end
        end
        %% Constant Table Callbacks
        % Updates the constant table definition
        function UpdateConstTable(self,src,event);
            % On cell change update the 
            Table = horzcat(self.Model.Conditions.Constant(1:end).(src.String{src.Value}));
            self.ConstTableUI.Data = Table;
        end
        % Makes changes to the original constants ###Will fail when horzcat
        % stacks things greater than size 1 in the second dimension
        function ConstTableEditCallback(self,src,event);
            self.Model.Conditions.Constant(event.Indices(2)).(self.ConstSelectorUI.String{self.ConstSelectorUI.Value})(event.Indices(1),1) = event.NewData;
        end
        function ExtendConstTableTitles(self,src,event);
            RunNumber = numel(self.Runs);
            for n = 1:RunNumber;
                CellTitle{n} = ['Run ',num2str(n)];
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
            for RunNumber = 1:numel(self.Runs);
                for ConstNumber = 1:numel(Fieldnames);
                    self.Model.Conditions.Constant(RunNumber).(Fieldnames{ConstNumber}) = Constants.(Fieldnames{ConstNumber})(:,:,RunNumber);
                end
            end
        end
        function LoadConstsCallback(self,src,event);
            Constants = LoadConstants(self,self.FileInputUI.String);
            AssignConstantsToModel(self,Constants);
            
            % Update the constant table titles
            self.ExtendConstTableTitles(src,event);
        end
        %% Perturbation Callbacks
        % Saves the selected row
        function UpdateSelectedPert(self,src,event);
            if ~isempty(event.Indices);
                self.SelectedPert = event.Indices(1);
            end
        end
        % Adds perturbation
        function AddPerturbation(self,src,event);
            % Add empty cell to table
            self.PertTableUI.Data = [self.PertTableUI.Data;cell(1,5)];
        end
        % Removes perturbation
        function RemovePerturbation(self,src,event);
            % Removes the currently chosen row from the table
            self.PertTableUI.Data = [self.PertTableUI.Data(1:self.SelectedPert-1,:);self.PertTableUI.Data(self.SelectedPert+1:end,:)];
        end
        % Updates the perturbation table display
        function UpdatePertTableDefinition(self,src,event);
            RunStrings = num2str(1:numel(self.Runs));
            RunCells = strsplit(RunStrings,' ');
            % If the caller is from adding a new run
            if strcmp(src.Tag,'RunTableAddButton');
                % Update the table - only the first column has changed
                ChunkStrings = num2str(1:numel(self.Runs(1).Chunks));
                ChunkCells = strsplit(ChunkStrings,' ');
                fmt = {RunCells};
                set(self.PertTableUI,'ColumnFormat',fmt,...
                                     'ColumnEditable',[true,true,true,true,true]);
            % If the caller is a change to the table itself
            elseif strcmp(src.Tag,'PertTable');
                % Update all four columns
                Index = str2double(self.PertTableUI.Data{event.Indices(1),1});
                ChunkStrings = num2str(1:numel(self.Runs(Index).Chunks));
                ChunkCells = strsplit(ChunkStrings,' ');
                InitNames = fieldnames(self.Model.Conditions.Initial);
                
                if event.Indices(2) == 3;
                    Number = numel(self.Model.Conditions.Initial.(event.NewData));
                    NumCells = strsplit(num2str(1:Number),' ');
                    if Number==1;
                        fmt = {RunCells,ChunkCells,[InitNames'],{'1'},'char'};
                    else
                        fmt = {RunCells,ChunkCells,[InitNames'],NumCells,'char'};
                    end
                else
                    fmt = {RunCells,ChunkCells,[InitNames'],'char','char'};
                end
                set(self.PertTableUI,'ColumnFormat',fmt);
            else
            % Otherwise error out
                self.UpdateLogBox('Unknown error in perturbation table update');
            end
        end
        function LoadPerts(self,src,event);
            Flag = 0;
            if isempty(self.Model);
                self.UpdateLogBox('Please instantiate model first');
            elseif isempty(self.RunTableUI.Data);
                self.UpdateLogBox('No runs to load');
            else
                if isempty(self.FileInputUI.String);
                    self.SetInputFilepath;
                end
                PertMatrix = ncread(self.FileInputUI.String,'/Replication/Perturbation_Matrix');
                MaxRuns = size(self.RunTableUI.Data,1);
                if size(PertMatrix,2)~=1;
                    for PMIndex = 1:size(PertMatrix,1);
                        CurrentPert = strsplit(strtrim(PertMatrix(PMIndex,:)),',');
                        MaxChunks = numel(self.Runs(str2double(CurrentPert{1})).Chunks);
                        if ~(str2double(CurrentPert{1})>MaxRuns) && ~(str2double(CurrentPert{2})>MaxChunks);
                            PertExists = sum(strcmp(CurrentPert{3},self.PertTableUI.Data(:,3)) & str2double(CurrentPert(1))==str2double(self.PertTableUI.Data(:,1)) & str2double(CurrentPert{2})==str2double(self.PertTableUI.Data(:,2)));
                            if ~PertExists;
                                self.Runs(str2double(CurrentPert{1})).Chunks(str2double(CurrentPert{2})).AddPerturbation(CurrentPert{3},CurrentPert{4},CurrentPert{5});
                                self.PertTableUI.Data = [self.PertTableUI.Data;CurrentPert];
                            end
                        else
                            Flag = 1;
                        end
                    end
                else
                    self.UpdateLogBox('No perturbations to load');
                end
                if Flag==1;
                    self.UpdateLogBox('Some perturbations were skipped');
                end
            end
        end
        %% Variable Table Callbacks
        % Adds a variable
        function AddVariable(self,src,event);
            self.VarTableUI.Data = [self.VarTableUI.Data;cell(1,3)];
        end
        % Removes currently selected variable
        function RmVariable(self,src,event);
            self.VarTableUI.Data = [self.VarTableUI.Data(1:self.VarIndices(1)-1,:);self.VarTableUI.Data((self.VarIndices(1)+1):end,:)];
        end
        % Stores the currently selected variable
        function UpdateSelectedVar(self,src,event);
            self.VarIndices = event.Indices;
        end
        % Sets the currently specified vairables
        function GetVariables(self,src,event);
            if ~isempty(self.Model);
                if ~isempty(self.Model.Conditions.Variable);
                    Vars = self.Model.Conditions.Variable;
                    self.VarTableUI.Data = Vars;
                end
            end
        end
        % Updates the data for the variable table
        function UpdateVariableTable(self,src,event);
            % If the call comes from the addition of a run
            if strcmp(src.Tag,'RunTableAddButton');
                % Just process the first column
                ConstNames = fieldnames(self.Model.Conditions.Constant);
                fmt = {ConstNames'};
                set(self.VarTableUI,'ColumnFormat',fmt);
                self.VarTableUI.ColumnEditable = [true,true,true];
            % Otherwise, if the call is from the table itself
            elseif strcmp(src.Tag,'VarTable') && event.Indices(2)==1;
                % Process all the columns
                ConstNames = fieldnames(self.Model.Conditions.Constant);
                Number = numel(self.Model.Conditions.Constant.(event.NewData));
                NumCell = strsplit(num2str(1:Number),' ');
                if Number==1;
                    fmt = {ConstNames',{'1'},'char'};
                else
                    fmt = {ConstNames',NumCell,'char'};
                end
                set(self.VarTableUI,'ColumnFormat',fmt);
                self.VarTableUI.ColumnEditable = [true,true,true];
            elseif event.Indices(2)==2 || event.Indices(2)==3;
            else
                self.UpdateLogBox('Unexpected error with variable table');
            end
        end
        function LoadVars(self,src,event);
            if isempty(self.Model);
                self.UpdateLogBox('Please instantiate model first');
            elseif isempty(self.RunTableUI.Data);
                self.UpdateLogBox('No runs to load');
            else
                if isempty(self.FileInputUI.String);
                    self.SetInputFilepath;
                end
                VarMatrix = ncread(self.FileInputUI.String,'/Replication/Variable_Matrix');
                if size(VarMatrix,2)~=1;
                    for VMIndex = 1:size(VarMatrix,1);
                        CurrentVar = strsplit(strtrim(VarMatrix(VMIndex,:)),',');
                        self.Model.Conditions.AddVariable(CurrentVar{1},CurrentVar{2},CurrentVar{3});
                        self.VarTableUI.Data = [self.VarTableUI.Data;CurrentVar];
                    end
                else
                    self.UpdateLogBox('No variables to load');
                end
            end
        end
        %% Finalise
        function Finalise(self,src,event);
            for RunIndex = 1:numel(self.Runs);
                for ChunkIndex = 1:numel(self.Runs(RunIndex).Chunks);
                    self.Runs(RunIndex).Chunks(ChunkIndex).Perturbations = [];
                end
            end
            % Perturbations
            for n = 1:size(self.PertTableUI.Data,1);
                self.Runs(str2double(self.PertTableUI.Data{n,1})).Chunks(str2double(self.PertTableUI.Data{n,2})).AddPerturbation(self.PertTableUI.Data{n,3},self.PertTableUI.Data{n,4},self.PertTableUI.Data{n,5});
            end
            
            % Variables
            for n = 1:size(self.VarTableUI.Data,1);
                Input1 = self.VarTableUI.Data{n,1};
                if ~isempty(self.Model.Conditions.Variable);
                    VarExists = strcmp(Input1,vertcat(self.Model.Conditions.Variable{:,1}));
                    if sum(VarExists)>0;
                        self.Model.Conditions.Variable(VarExists,:) = [];
                    else
                    end
                end
                Input2 = str2double(self.VarTableUI.Data{n,2});
                Input3 = [self.VarTableUI.Data{n,3}];
                
                self.Model.Conditions.AddVariable(Input1,Input2,Input3);
            end
            
            % Number of timesteps
            for Run_Index = 1:numel(self.Runs);
                for Chunk_Index = 1:numel(self.Runs(Run_Index).Chunks);
                    Chunk_Step_Number{Run_Index}(Chunk_Index) = numel(self.Runs(Run_Index).Chunks(Chunk_Index).TimeIn(1):self.Runs(Run_Index).Chunks(Chunk_Index).TimeIn(3):self.Runs(Run_Index).Chunks(Chunk_Index).TimeIn(2));
                end
                Run_Step_Number(Run_Index) = sum(Chunk_Step_Number{Run_Index});
            end
            self.Model.Total_Steps = Run_Step_Number;
            self.Model.dt = self.Runs(1).Chunks(1).TimeIn(3);
            
            % Subduction
            MaxMetamorphism_Tracked = ceil(((self.Model.Conditions.Constant.Metamorphism_Mean_Lag)+(4*self.Model.Conditions.Constant.Metamorphism_Spread)+(self.Runs(1).Chunks(end).TimeIn(2)))/self.Model.Conditions.Constant.Metamorphism_Resolution);
            self.Model.Conditions.Constant.Metamorphism_Gauss = gaussmf([-self.Model.Conditions.Constant.Metamorphism_Spread*4:self.Model.Conditions.Constant.Metamorphism_Resolution:self.Model.Conditions.Constant.Metamorphism_Spread*4],[self.Model.Conditions.Constant.Metamorphism_Spread,0]');
            self.Model.Conditions.Constant.Metamorphism_Gauss = self.Model.Conditions.Constant.Metamorphism_Gauss/sum(self.Model.Conditions.Constant.Metamorphism_Gauss);
            self.Model.Metamorphism = zeros(1,MaxMetamorphism_Tracked); %*10000*1e13;
            
            self.CheckFileExists;
            self.OutputFile = [self.OutputFilepath,'\',self.OutputFilename];
            if strcmp(self.FilenameWarningUI.String,'File exists');
                delete(self.OutputFile);
            end
        end
        function Validate(self,src,event);
            if numel(self.Runs)==0;
                self.UpdateLogBox('No run details provided');
            elseif isempty(self.OutputFilepath) || isempty(self.OutputFilename);
                self.UpdateLogBox('Filename or filepath is empty');
            else
                self.ValidatedFlag = 1;
            end
        end
        %% Run
        function RunModel(self,src,event);
            profile on;
            self.ColourBox.BackgroundColor = [1,1,0.5];
            drawnow;
            self.Validate(src,event);
            self.ValidateRuns(src,event);
            
            if self.ValidatedFlag;
                self.Finalise(src,event);
                
                DateTime(1) = datetime('now');
                self.UpdateLogBox('Starting...');
                
                self.Model.PrepareNetCDF(self.OutputFile,self.Runs);
                
                % Split the model
                ModelCells = self.Model.Split;
                % Parameter Redefinition
                for n = 1:numel(ModelCells);
                    ModelCells{n}.Conditions.RedefineConstants;
                    ModelCells{n}.Conditions.RedefineInitial;
                    ModelCells{n}.Conditions.UpdatePresent;
                    ModelCells{n}.CalculateDependents;
                end
                
                RunNumber = numel(self.Runs);
                
%                 try
                % Parallel loop for runs
                for Run = 1:RunNumber;
                    % Single model is taken from split cell array
                    SingleRunModel = ModelCells{Run};
                    
                    % Preallocate output arrays
                    DataChunks = cell(1:numel(self.Runs(Run).Chunks));
                    TimeChunks = cell(1:numel(self.Runs(Run).Chunks));
                    ConstChunks = cell(1:numel(self.Runs(Run).Chunks));
                    LysChunks = cell(1:numel(self.Runs(Run).Chunks));
                    
                    % Loop for each chunk
                    for Chunk = 1:numel(self.Runs(Run).Chunks);
                        % Apply the relevant perturbations on a per model-run basis
                        SingleRunModel.Conditions.Perturb({self.Runs(Run).Perturbations;self.Runs(Run).Chunks(Chunk).Perturbations});
                        
                        % Separate and save the time data
                        Time_In = self.Runs(Run).Chunks(Chunk).TimeIn(1):self.Runs(Run).Chunks(Chunk).TimeIn(3):self.Runs(Run).Chunks(Chunk).TimeIn(2);
                        Time_Out = (self.Runs(Run).Chunks(Chunk).TimeOut(1):self.Runs(Run).Chunks(Chunk).TimeOut(3):self.Runs(Run).Chunks(Chunk).TimeOut(2))';
                        TimeChunks{Chunk} = Time_Out;
                        
                        % Create anonymous function
                        ODEFunc = eval(['@(t,y)',self.Model.CoreFcn,'(t,y,SingleRunModel)']);
                        
                        % Run the solver
                        [DataChunks{Chunk},ConstChunks{Chunk},LysChunks{Chunk}] = self.Model.SolverFcn(ODEFunc,Time_In,SingleRunModel.Conditions.Initial.Conditions,Time_Out,SingleRunModel);
                        
                        % Reset the initial conditions
                        SingleRunModel.Conditions.Initial.Conditions = DataChunks{Chunk}(end,:);
                        SingleRunModel.Conditions.Deal(Run);
                    end
                    
                    % Accumulate chunks into runs (as cells of cells)
                    DataRuns{Run} = vertcat(DataChunks{:});
                    TimeRuns{Run} = vertcat(TimeChunks{:});
                    ConstRuns{Run} = vertcat(ConstChunks{:});
                    LysRuns{Run} = vertcat(LysChunks{:});
                    
                    % Assign to model object
                    ModelCells{Run}.Data = DataRuns{Run};
                    ModelCells{Run}.Time = TimeRuns{Run};
                    ModelCells{Run}.Lysocline = LysRuns{Run};
                    ModelCells{Run}.AddConst(ConstRuns{Run});
                    
                    % Display when run is complete
                    Time = clock;
                    self.UpdateLogBox(['Run number ',num2str(Run),' of ',num2str(numel(self.Runs)),' complete @ ',char(datetime('now','Format','HH:mm:ss'))]);
                    %                 fprintf(['\nRun number ',num2str(Run),' of ',num2str(numel(self.Runs)),' complete \n']);
                    
                    % Save data to file when each run is done
                    ModelCells{Run}.Save(self.OutputFile,Run);
                end
%                 catch ME
%                     self.UpdateLogBox('Error!');
%                 end
                  
                
                % Reconstitute the disparate data into the model object
                self.Model.Merge(ModelCells);
                
                % Save the replication data
                self.AddGroup(self.OutputFile);
                self.DefineDimensions(self.OutputFile);
                self.DefineVariables(self.OutputFile);
                self.ProcessReplicatoryData;
                self.AddReplicatoryData(self.OutputFile);
                
                % Print to log box
                self.UpdateLogBox('Successfully completed');

                self.ColourBox.BackgroundColor = [0,0.5,0.3];
                profile off;
            end
        end
        function RunModelFnc(self,src,event);

        end
        %% Saving        
        function AddGroup(self,Filename);
            FileID = netcdf.open(Filename,'WRITE');
            netcdf.reDef(FileID);
            
            RepGrpID = netcdf.defGrp(FileID,'Replication');
            
            netcdf.close(FileID);
        end
        function DefineDimensions(self,Filename);
            FileID = netcdf.open(Filename,'WRITE');
            Dim_r1 = {'r_1',size(self.RunTableUI.Data,1)};
            Dim_r2 = {'r_2',8};
            Dim_p1 = {'p_1',size(self.PertTableUI.Data,1)};
            Dim_p2 = {'p_2',size(char(join(self.PertTableUI.Data,',')),2)};
            Dim_v1 = {'v_1',size(self.VarTableUI.Data,1)};
            Dim_v2 = {'v_2',size(char(join(self.VarTableUI.Data,',')),2)};
            Dim_i2 = {'i_2',8};
            
            netcdf.defDim(FileID,Dim_r1{1},Dim_r1{2});
            netcdf.defDim(FileID,Dim_r2{1},Dim_r2{2});
            
            netcdf.defDim(FileID,Dim_i2{1},Dim_i2{2});
            
            if Dim_p1{2}~=0;
                netcdf.defDim(FileID,Dim_p1{1},Dim_p1{2});
                netcdf.defDim(FileID,Dim_p2{1},Dim_p2{2});
            end
            
            if Dim_v1{2}~=0;
                netcdf.defDim(FileID,Dim_v1{1},Dim_v1{2});
                netcdf.defDim(FileID,Dim_v2{1},Dim_v2{2});
            end
            
            netcdf.close(FileID);
        end
        function DefineVariables(self,Filename);
            FileID = netcdf.open(Filename,'WRITE');
            RepGrpID = netcdf.inqNcid(FileID,'Replication');
            
            CurrentDims = {'r_1','r_2'};
            netcdf.defVar(RepGrpID,'Run_Matrix','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2})]);
            
            CurrentDims = {'r','i_2'};
            netcdf.defVar(RepGrpID,'Initial_Matrix','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2})]);
            
            if ~isempty(self.PertTableUI.Data);
                CurrentDims = {'p_1','p_2'};
                netcdf.defVar(RepGrpID,'Perturbation_Matrix','char',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2})]);
            else
                netcdf.defVar(RepGrpID,'Perturbation_Matrix','char',[]);
            end
            
            if ~isempty(self.VarTableUI.Data);
                CurrentDims = {'v_1','v_2'};
                netcdf.defVar(RepGrpID,'Variable_Matrix','char',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2})]);
            else
                netcdf.defVar(RepGrpID,'Variable_Matrix','char',[]);
            end
            
            netcdf.close(FileID);
        end
        function ProcessReplicatoryData(self);
            self.RunMatrix = self.RunTableUI.Data;
            self.PertMatrix = char(join(self.PertTableUI.Data,','));
            self.VarMatrix = char(join(self.VarTableUI.Data,','));
            self.InitMatrix = vertcat(self.Model.Conditions.Initial(:).Conditions);
        end
        function AddReplicatoryData(self,Filename);
            FileID = netcdf.open(Filename,'WRITE');
            RepGrpID = netcdf.inqNcid(FileID,'Replication');
            
            Run_MatrixID = netcdf.inqVarID(RepGrpID,'Run_Matrix');
            netcdf.putVar(RepGrpID,Run_MatrixID,self.RunMatrix);
            
            Init_MatrixID = netcdf.inqVarID(RepGrpID,'Initial_Matrix');
            netcdf.putVar(RepGrpID,Init_MatrixID,self.InitMatrix);
            
            if ~isempty(self.PertMatrix);
                Pert_MatrixID = netcdf.inqVarID(RepGrpID,'Perturbation_Matrix');
                netcdf.putVar(RepGrpID,Pert_MatrixID,self.PertMatrix);
            end
            
            if ~isempty(self.VarMatrix);
                Var_MatrixID = netcdf.inqVarID(RepGrpID,'Variable_Matrix');
                netcdf.putVar(RepGrpID,Var_MatrixID,self.VarMatrix);
            end
            
            netcdf.close(FileID);
        end
        %% Loading Data
        function FullCopy(self,FileInput);
            self.FileInputUI.String = FileInput;
            
            Model = ncreadatt(FileInput,'/','Model');
            Core = ncreadatt(FileInput,'/','Core');
            Solver = ncreadatt(FileInput,'/','Solver');
            self.ModelUI.Value = find(strcmp(self.ModelUI.String,Model));
            self.GetAvailableCores;
            self.CoreUI.Value = find(strcmp(self.CoreUI.String,Core));
            self.SolverUI.String{1} = Solver;            
            
            addpath(genpath(['./../../',self.ModelUI.String{self.ModelUI.Value}]));
            self.InstantiateModel;
            
            self.LoadRuns;
            
            Constant = self.LoadConstants(FileInput);
            self.AssignConstantsToModel(Constant);
            
            self.LoadPerts;
            self.LoadVars;
            self.LoadInits;
        end
        function FullCopyWrapper(self,src,event);
            if isempty(self.FileInputUI.String);
                self.UpdateLogBox('Please select an input file');
            else
                self.FullCopy(self.FileInputUI.String);
            end
        end
        function DataIDs = GetDataIDs(self,Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            DataIDs = netcdf.inqVarIDs(DataGrpID);    
            netcdf.close(FileID);
        end
        function DataNames = GetDataNames(self,Filename);
            DataIDs = self.GetDataIDs(Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            for DataNumber = 1:numel(DataIDs);
                [DataNames{DataNumber},~,~,~] = netcdf.inqVar(DataGrpID,DataIDs(DataNumber));
            end
            netcdf.close(FileID);
        end
        function Data = LoadData(self,Filename);
            DataIDs = self.GetDataIDs(Filename);
            DataNames = self.GetDataNames(Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            Data = [];
            for DataNumber = 2:numel(DataNames);
                Data = [Data;netcdf.getVar(DataGrpID,DataIDs(DataNumber))];
            end
            Data = permute(Data,[2,1,3]);
            netcdf.close(FileID);
        end
        function AssignDataToModel(self,Data);
                self.Model.Data = Data;
        end
        function LoadDataIntoModel(self,src,event);
            Data = self.LoadData(self.FileInputUI.String);
            self.AssignDataToModel(Data);
        end
        function LoadFinal(self,src,event);
            if isempty(self.FileInputUI.String);
                self.UpdateLogBox('Please select an input file');
            elseif isempty(self.Model);
                self.UpdateLogBox('Please instantiate the model first');
            else
                Data = self.LoadData(self.FileInputUI.String);
                if numel(self.Runs)==size(Data,3);
                    for RunNumber = 1:numel(self.Runs);
                        self.Model.Conditions.Initial(RunNumber).Conditions = Data(end,[1,2,4:end],RunNumber);
                    end
                elseif numel(self.Runs)>size(Data,3);
                    for RunNumber = 1:numel(self.Runs);
                        self.Model.Conditions.Initial(RunNumber).Conditions = Data(end,:,1);
                    end
                    self.UpdateLogBox('More runs than initial conditions, used output from run 1');
                elseif numel(self.Runs)<size(Data,3);
                    for RunNumber = 1:numel(self.Runs);
                        self.Model.Conditions.Initial(RunNumber).Conditions = Data(end,:,RunNumber);
                    end
                    self.UpdateLogBox('More initial conditions than runs');
                end
                self.Model.Conditions.Deal(1:2); %% ### ONLY WORKS FOR TWO.
            end
        end
        %% Log box
        function UpdateLogBox(self,Message);
            self.LogBoxUI.String = [self.LogBoxUI.String;Message];
            LogBoxObj = findjobj(self.LogBoxUI);
            LogBoxEdit = LogBoxObj.getComponent(0).getComponent(0);
            LogBoxEdit.setCaretPosition(LogBoxEdit.getDocument.getLength);
            drawnow;
        end
    end
end
