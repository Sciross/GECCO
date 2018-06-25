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
        PlotRunSelectorUI = 1;
        s
        ColourBox
        SubplotIndex = 1;
        Tab1Handle
        Tab2Handle
        BoxSize = [0.4,0.175];
        Colours
        ModelDirectory
    end
    methods
        function self = GECCOGUI(FileInput);
            Model_Filepath = which('GECCOGUI.m');
            Model_Dir = Model_Filepath(1:end-10);
%             CurrentDir = dir('.');
%             CurrentDirRight = sum(strcmp(vertcat({CurrentDir(:).name}),'GECCOGUI.m'));
            if isempty(Model_Filepath);
                error('Model not found, add to path');
            end
            
            self.ModelDirectory = Model_Dir;
            Split_Dir = strsplit((Model_Dir),'\');
            disp([Split_Dir{7},' GUI instantiated']);
            
            if nargin==0;
                FileInput = 'none';
            end
            
            Temp = load('Colours.mat');
            self.Colours = Temp.Colours;
            
            if ~strcmp(FileInput,'-headless');
                self.Handle = figure('Position',[100,100,1100,600]); 
                self.Size = get(self.Handle,'Position');
%                 self.LogMessages = {'Begun'};
                addpath([self.ModelDirectory,'..\..\Solvers\']);

                %% Tabbing
                TabGroupHandle = uitabgroup('Parent',self.Handle,...
                                            'SelectionChangedFcn',@self.TabChangeCallback);
                self.Tab1Handle = uitab('Parent',TabGroupHandle,'Title','Run Model');
                self.Tab2Handle = uitab('Parent',TabGroupHandle,'Title','Plot Data');

                %% Filepath
                FileInputLabelUI = uicontrol('Style','text',...
                                             'Units','Normalized',...
                                             'Position',[0.017,0.91,0.091,0.087],...
                                             'HorizontalAlignment','left',...
                                             'String','Input Filepath',...
                                             'Parent',self.Tab1Handle);
                self.FileInputUI = uicontrol('Style','edit',...
                                             'Units','Normalized',...
                                             'Position',[0.0173,0.9336,0.4106,0.035],...
                                             'HorizontalAlignment','left',...
                                             'Parent',self.Tab1Handle);
                FileInputBrowseButton = uicontrol('Style','Pushbutton',...
                                                  'String','Browse',...
                                                  'Units','Normalized',...
                                                  'Position',[0.437,0.9336,0.046,0.035],...
                                                  'Callback',@self.SetInputFilepath,...
                                                  'Parent',self.Tab1Handle);
                FilepathLabelUI = uicontrol('Style','text',...
                                            'Units','Normalized',...
                                            'Position',[0.017,0.837,0.091,0.087],...
                                            'HorizontalAlignment','left',...
                                            'String','Output Filepath',...
                                            'Parent',self.Tab1Handle);
                self.FilepathUI = uicontrol('Style','edit',...
                                            'Units','Normalized',...
                                            'Position',[0.0173,0.865,0.4106,0.035],...
                                            'HorizontalAlignment','left',...
                                            'Parent',self.Tab1Handle);
                FilepathBrowseButton = uicontrol('Style','Pushbutton',...
                                                 'String','Browse',...
                                                 'Units','Normalized',...
                                                 'Position',[0.437,0.865,0.046,0.035],...
                                                 'Callback',@self.SetOutputFilepath,...
                                                 'Parent',self.Tab1Handle);
                FilenameLabelUI = uicontrol('Style','text',...
                                            'Units','Normalized',...
                                            'Position',[0.017,0.75,0.091,0.087],...
                                            'HorizontalAlignment','left',...
                                            'String','Filename',...
                                            'Parent',self.Tab1Handle);
                self.FilenameUI = uicontrol('Style','edit',...
                                            'Units','Normalized',...
                                            'Position',[0.063,0.8024,0.3650,0.035],...
                                            'HorizontalAlignment','Left',...
                                            'Callback',@self.SetOutputFileCallback,...
                                            'Parent',self.Tab1Handle);
                self.FilenameWarningUI = uicontrol('Style','text',...
                                                   'Units','Normalized',...
                                                   'Position',[0.4370,0.8024,0.0912,0.035],...
                                                   'HorizontalAlignment','left',...
                                                   'String',' ',...
                                                   'Parent',self.Tab1Handle);
                %% Model, Core + Solver     
                ModelLabelUI = uicontrol('Style','text',...
                                         'Units','Normalized',...
                                         'Position',[0.0173,0.755,0.1369,0.035],...
                                         'String','Model',...
                                         'HorizontalAlignment','Left',...
                                         'Parent',self.Tab1Handle);
                self.ModelUI = uicontrol('Style','popupmenu',...
                                         'String','-',...
                                         'Units','Normalized',...
                                         'Position',[0.0173,0.7325,0.1369,0.035],...
                                         'Callback',@self.ChangeModelCallback,...
                                         'CreateFcn',@self.GetInstalledModels,...
                                         'Parent',self.Tab1Handle);

                CoreLabelUI = uicontrol('Style','text',...
                                        'Units','Normalized',...
                                        'Position',[0.0173,0.685,0.1369,0.035],...
                                        'String','Core',...
                                        'HorizontalAlignment','Left',...
                                        'Parent',self.Tab1Handle);
                self.CoreUI = uicontrol('Style','popupmenu',...
                                        'String',{'-'},...
                                        'Units','Normalized',...
                                        'Position',[0.0173,0.6626,0.1369,0.035],...
                                        'CreateFcn',@self.GetAvailableCores,...
                                        'Callback',@self.SelectCoreCallback,...
                                        'Parent',self.Tab1Handle);

                SolverLabelUI = uicontrol('Style','text',...
                                          'Units','Normalized',...
                                          'Position',[0.0173,0.615,0.1369,0.035],...
                                          'String','Solver',...
                                          'HorizontalAlignment','Left',...
                                          'Parent',self.Tab1Handle);
                self.SolverUI = uicontrol('Style','popupmenu',...
                                          'String',{'MySolver_2_Implicit_Trial','MySolver_15_Implicit_Trial'},...
                                          'Units','Normalized',...
                                          'Position',[0.0173,0.5927,0.1369,0.035],...
                                          'Callback',@self.SelectSolverCallback,...
                                          'Parent',self.Tab1Handle);

                %% Run Table
                RunTableLabelUI = uicontrol('Style','text',...
                                            'Units','Normalized',...
                                            'Position',[0.5,0.91,0.1369,0.0874],...
                                            'String','Run Details',...
                                            'HorizontalAlignment','Left',...
                                            'Parent',self.Tab1Handle);
                self.RunTableUI = uitable(self.Handle,...
                                          'Data',self.RunTableUI,...
                                          'Units','Normalized',...
                                          'Position',[0.5,0.8,self.BoxSize(1),self.BoxSize(2)],...
                                          'CellSelectionCallback',@self.UpdateRunIndices,...
                                          'CellEditCallback',@self.RunTableEditCallback,...
                                          'ColumnName',{'Run','Chunk','Start','End','Step','Start','End','Step'},...
                                          'ColumnWidth',{40,40,60,60,40,60,60,40},...
                                          'ColumnEditable',[true,true,true,true,true,true,true,true],...
                                          'Parent',self.Tab1Handle);
                RunTableAddButtonUI = uicontrol('Style','pushbutton',...
                                                'Units','Normalized',...
                                                'Position',[0.91,0.935,0.07,0.04],...
                                                'String','Add Run',...
                                                'Callback',@self.AddRunCallback,...
                                                'Tag','RunTableAddButton',...
                                                'Parent',self.Tab1Handle);
                ChunkTableAddButtonUI = uicontrol('Style','pushbutton',...
                                                  'Units','Normalized',...
                                                  'Position',[0.91,0.89,0.07,0.04],...
                                                  'String','Add Chunk',...
                                                  'Callback',@self.AddChunkCallback,...
                                                  'Parent',self.Tab1Handle);
                RunTableRmButtonUI = uicontrol('Style','pushbutton',...
                                               'Units','Normalized',...
                                               'Position',[0.91,0.845,0.07,0.04],...
                                               'String','Remove Entry',...
                                               'Callback',@self.RunTableRmEntry,...
                                               'Parent',self.Tab1Handle);
                RunLoadButtonUI = uicontrol('Style','pushbutton',...
                                            'Units','Normalized',...
                                            'Position',[0.91,0.8,0.07,0.04],...
                                            'String','Load',...
                                            'Callback',@self.LoadRuns,...
                                            'Parent',self.Tab1Handle);
                %% Initial Table
                InitialTableLabelUI = uicontrol('Style','text',...
                                                'Units','Normalized',...
                                                'Position',[0.0173,0.47,0.1369,0.0874],...
                                                'String','Initial Conditions',...
                                                'HorizontalAlignment','Left',...
                                                'Parent',self.Tab1Handle);
                self.InitSelectorUI = uicontrol('Style','popupmenu',...
                                                'Units','Normalized',...
                                                'Position',[0.0903,0.4703,0.1369,0.0874],...
                                                'String','-',...
                                                'Callback',@self.UpdateInitialTable,...
                                                'Parent',self.Tab1Handle);
                self.InitialTableUI = uitable(self.Handle,...
                                              'Data',self.InitialTableUI,...
                                              'Units','Normalized',...
                                              'Position',[0.0173,0.33,self.BoxSize(1),self.BoxSize(2)],...
                                              'ColumnEditable',[true],...
                                              'CellEditCallback',@self.InitTableEditCallback,...
                                              'Parent',self.Tab1Handle);
                InitLoadButtonUI = uicontrol('Style','pushbutton',...
                                             'Units','Normalized',...
                                             'Position',[0.42,0.465,0.07,0.04],...
                                             'String','Load',...
                                             'Callback',@self.LoadInits,...
                                             'Parent',self.Tab1Handle);
                InitLoadFinalButtonUI = uicontrol('Style','pushbutton',...
                                                  'Units','Normalized',...
                                                  'Position',[0.42,0.42,0.07,0.04],...
                                                  'String','Load Final',...
                                                  'Callback',@self.LoadFinal,...
                                                  'Parent',self.Tab1Handle);
                InitLoadOutgasButtonUI = uicontrol('Style','pushbutton',...
                                                   'Units','Normalized',...
                                                   'Position',[0.42,0.375,0.07,0.04],...
                                                   'String','Load Outgas',...
                                                   'Callback',@self.LoadOut,...
                                                   'Parent',self.Tab1Handle);
                InitLoadSeafloorButtonUI = uicontrol('Style','pushbutton',...
                                                     'Units','Normalized',...
                                                     'Position',[0.42,0.33,0.07,0.04],...
                                                     'String','Load Seafloor',...
                                                     'Callback',@self.LoadSea,...
                                                     'Parent',self.Tab1Handle);
                     
                %% Constant Table
                ConstTableLabelUI = uicontrol('Style','text',...
                                              'Units','Normalized',...
                                              'Position',[0.0173,0.2205,0.1369,0.0874],...
                                              'String','Constants',...
                                              'HorizontalAlignment','Left',...
                                              'Parent',self.Tab1Handle);
                self.ConstSelectorUI = uicontrol('Style','popupmenu',...
                                                 'Units','Normalized',...
                                                 'Position',[0.0903,0.2205,0.1369,0.0874],...
                                                 'String','-',...
                                                 'Callback',@self.UpdateConstTable,...
                                                 'Parent',self.Tab1Handle);
                self.ConstTableUI = uitable(self.Handle,...
                                            'Data',self.ConstTableUI,...
                                            'Units','Normalized',...
                                            'Position',[0.0173,0.060,0.4,0.175],...
                                            'ColumnEditable',[true,true,true,true,true,true,true],...
                                            'ColumnName',{'Run 1'},...
                                            'CellEditCallback',@self.ConstTableEditCallback,...
                                             'Parent',self.Tab1Handle);
                ConstLoadButtonUI = uicontrol('Style','pushbutton',...
                                              'Units','Normalized',...
                                              'Position',[0.42,0.195,0.07,0.04],...
                                              'String','Load',...
                                              'Callback',@self.LoadConstsCallback,...
                                              'Parent',self.Tab1Handle);
                %% Perturbation Table
                PertTableLabelUI = uicontrol('Style','text',...
                                             'Units','Normalized',...
                                             'Position',[0.5,0.7,0.1369,0.0874],...
                                             'String','Perturbations',...
                                             'HorizontalAlignment','Left',...
                                             'Parent',self.Tab1Handle);
                self.PertTableUI = uitable(self.Handle,...
                                           'Data',cell(0,5),...
                                           'Units','Normalized',...
                                           'Position',[0.5,0.59,self.BoxSize(1),self.BoxSize(2)],...
                                           'ColumnEditable',[true,true,true,true,true],...
                                           'ColumnName',{'Run','Chunk','Parameter','Depth','Change To'},...
                                           'CellEditCallback',@self.UpdatePertTableDefinition,...
                                           'CellSelectionCallback',@self.UpdateSelectedPert,...
                                           'Tag','PertTable',...
                                           'ColumnWidth',{40,40,100,40,180},...
                                           'Parent',self.Tab1Handle);
                AddPertButtonUI = uicontrol('Style','pushbutton',...
                                            'Units','Normalized',...
                                            'Position',[0.93,0.71,0.0274,0.0524],...
                                            'String','+',...
                                            'Callback',@self.AddPerturbation,...
                                            'Parent',self.Tab1Handle);
                RmPertButtonUI = uicontrol('Style','pushbutton',...
                                           'Units','Normalized',...
                                           'Position',[0.93,0.66,0.0274,0.0524],...
                                           'String','-',...
                                           'Callback',@self.RemovePerturbation,...
                                           'Parent',self.Tab1Handle);
                PertLoadButtonUI = uicontrol('Style','pushbutton',...
                                             'Units','Normalized',...
                                             'Position',[0.91,0.59,0.07,0.04],...
                                             'String','Load',...
                                             'Callback',@self.LoadPerts,...
                                             'Parent',self.Tab1Handle);
                %% Variable Table                 
                VarTableLabelUI = uicontrol('Style','text',...
                                            'Units','Normalized',...
                                            'Position',[0.5,0.45,0.1369,0.0874],...
                                            'String','Variables',...
                                            'HorizontalAlignment','Left',...
                                            'Parent',self.Tab1Handle);
                self.VarTableUI = uitable(self.Handle,...
                                          'Data',cell(0,3),...
                                          'Units','Normalized',...
                                          'Position',[0.5009,0.33,self.BoxSize(1),self.BoxSize(2)],...
                                          'Tag','VarTable',...
                                          'ColumnName',{'Parameter','Depth','Change To'},...
                                          'CreateFcn',@self.GetVariables,...
                                          'CellSelectionCallback',@self.UpdateSelectedVar,...
                                          'CellEditCallback',@self.UpdateVariableTable,...
                                          'ColumnWidth',{100,40,200},...
                                          'Parent',self.Tab1Handle);
                AddVarButtonUI = uicontrol('Style','pushbutton',...
                                           'Units','Normalized',...
                                           'Position',[0.93,0.45,0.0274,0.0524],...
                                           'String','+',...
                                           'Callback',@self.AddVariable,...
                                           'Parent',self.Tab1Handle);
                RmVarButtonUI = uicontrol('Style','pushbutton',...
                                           'Units','Normalized',...
                                           'Position',[0.93,0.4,0.0274,0.0524],...
                                           'String','-',...
                                           'Callback',@self.RmVariable,...
                                           'Parent',self.Tab1Handle);
                VarLoadButtonUI = uicontrol('Style','pushbutton',...
                                            'Units','Normalized',...
                                            'Position',[0.91,0.33,0.07,0.04],...
                                            'String','Load',...
                                            'Callback',@self.LoadVars,...
                                            'Parent',self.Tab1Handle);

                %% Log Box
                self.LogBoxUI = uicontrol('Style','edit',...
                                          'Units','Normalized',...
                                          'Position',[0.5,0.060,0.4,0.175],...
                                          'String',self.LogMessages,...
                                          'HorizontalAlignment','Left',...
                                          'Max',1000,...
                                          'Parent',self.Tab1Handle);

                %% Finalisation
                ModelInstantiationButton = uicontrol('Style','pushbutton',...
                                                     'String','Instantiate Model',...
                                                     'Units','Normalized',...
                                                     'Position',[0.28,0.685,0.0912,0.0874],...
                                                     'Callback',@self.InstantiateModel,...
                                                     'Parent',self.Tab1Handle);
                                                 
                RunBoxUI = uicontrol('Style','pushbutton',...
                                     'String','Run Model',...
                                     'Units','Normalized',...
                                     'Position',[0.28,0.59,0.0912,0.0874],...
                                     'Callback',@self.RunModel,...
                                     'Parent',self.Tab1Handle);

                %% Loading
                LoadAllBoxUI = uicontrol('Style','pushbutton',...
                                         'String','Load All',...
                                         'Units','Normalized',...
                                         'Position',[0.18,0.685,0.0912,0.0874],...
                                         'Callback',@self.FullCopyWrapper,...
                                         'Parent',self.Tab1Handle);
                LoadDataBoxUI = uicontrol('Style','pushbutton',...
                                         'String','Load Data',...
                                         'Units','Normalized',...
                                         'Position',[0.18,0.59,0.0912,0.0874],...
                                         'Callback',@self.LoadDataIntoModel,...
                                         'Parent',self.Tab1Handle);
                                     
                %% Extra buttons
                ResetButton = uicontrol('Style','pushbutton',...
                                        'String','Reset',...
                                        'Units','Normalized',...
                                        'Position',[0.38,0.685,0.0912,0.0874],...
                                        'Callback',@self.Reset,...
                                        'Parent',self.Tab1Handle);
                                                 
                ExtraButton2 = uicontrol('Style','pushbutton',...
                                         'String','Extra2',...
                                         'Units','Normalized',...
                                         'Position',[0.38,0.59,0.0912,0.0874],...
                                         'Parent',self.Tab1Handle);

                %% Plot Control
                self.PlotRunSelectorUI = uicontrol('Style','popupmenu',...
                                                   'Units','Normalized',...
                                                   'Position',[0.0173,0.9423,0.1369,0.035],...
                                                   'String','-',...
                                                   'Parent',self.Tab2Handle,...
                                                   'Callback',@self.SelectPlot);
                PlotsRightArrowUI = uicontrol('Style','pushbutton',...
                                              'Units','Normalized',....
                                              'Position',[0.95,0.5,0.035,0.15],...
                                              'String','>',...
                                              'Parent',self.Tab2Handle,...
                                              'Callback',@self.PlotRight);
                PlotsLeftArrowUI = uicontrol('Style','pushbutton',...
                                             'Units','Normalized',....
                                             'Position',[0.02,0.5,0.035,0.15],...
                                             'String','<',...
                                             'Parent',self.Tab2Handle,...
                                             'Callback',@self.PlotLeft);

                self.s{1} = subplot(5,1,1,'Parent',self.Tab2Handle);
                self.s{2} = subplot(5,1,2,'Parent',self.Tab2Handle);
                self.s{3} = subplot(5,1,3,'Parent',self.Tab2Handle);
                self.s{4} = subplot(5,1,4,'Parent',self.Tab2Handle);
                self.s{5} = subplot(5,1,5,'Parent',self.Tab2Handle);

                %% Colour box
                self.ColourBox = uicontrol('Style','text',...
                                           'Units','Normalized',...
                                           'Position',[0.91,0.065,0.05625,0.1],...
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
                        self.SubplotIndex=1;
                        self.RecreateSubplots;
                        
                        subplot(self.s{1});
                        p{1} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Data(1,:,self.PlotRunSelectorUI.Value)*1e6,'Color',self.Colours.black);
                        ylabel({'CO_2','(ppm)'});
                        
                        subplot(self.s{2});
                        p{2} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Data(2,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.green);
                        ylabel({'Algae','(mol/m^3)'});
                        
                        subplot(self.s{3});
                        p{3} = plot(self.Model.Time(1,:,1),self.Model.Data(3,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.blue);
                        hold on
                        plot(self.Model.Time(1,:,1),self.Model.Data(4,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.darkblue);
                        hold off
                        ylabel({'Phosphate','(mol/m^3)'});
                        
                        subplot(self.s{4});
                        p{4} = plot(self.Model.Time(1,:,1),self.Model.Data(5,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.blue);
                        hold on
                        plot(self.Model.Time(1,:,1),self.Model.Data(6,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.darkblue);
                        hold off
                        ylabel({'DIC','(mol/m^3)'});
                        
                        subplot(self.s{5});
                        p{5} = plot(self.Model.Time(1,:,1),self.Model.Data(7,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.blue);
                        hold on
                        plot(self.Model.Time(1,:,1),self.Model.Data(8,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.darkblue);
                        hold off
                        ylabel({'Alkalinity','(mol/m^3)'});
                        
                        xlabel('Time (yr)');
                        set([self.s{1:4}],'XTick',[]);
                        linkaxes([self.s{1:5}],'x');
                    end
                end
            end
        end
        function SelectPlot(self,src,event);
            self.RecreateSubplots;
            if self.SubplotIndex==1;
                subplot(self.s{1});
                p{1} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Data(1,:,self.PlotRunSelectorUI.Value)*1e6,'Color',self.Colours.black);
                ylabel({'CO_2','(ppm)'});
                
                subplot(self.s{2});
                p{2} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Data(2,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.green);
                ylabel({'Algae','(mol/m^3)'});
                
                subplot(self.s{3});
                p{3} = plot(self.Model.Time(1,:,1),self.Model.Data(3,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.blue);
                hold on
                plot(self.Model.Time(1,:,1),self.Model.Data(4,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.darkblue);
                hold off
                ylabel({'Phosphate','(mol/m^3)'});
                
                subplot(self.s{4});
                p{4} = plot(self.Model.Time(1,:,1),self.Model.Data(5,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.blue);
                hold on
                plot(self.Model.Time(1,:,1),self.Model.Data(6,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.darkblue);
                hold off
                ylabel({'DIC','(mol/m^3)'});
                
                subplot(self.s{5});
                p{5} = plot(self.Model.Time(1,:,1),self.Model.Data(7,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.blue);
                hold on
                plot(self.Model.Time(1,:,1),self.Model.Data(8,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.darkblue);
                hold off
                ylabel({'Alkalinity','(mol/m^3)'});
                
                xlabel('Time (yr)');
                set([self.s{1:4}],'XTick',[]);
                linkaxes([self.s{1:5}],'x');
                xlim([0,max(self.Model.Time(:,:,self.PlotRunSelectorUI.Value))]);
                
            elseif self.SubplotIndex==2;
                subplot(self.s{1});
                p{1} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Data(9,:,self.PlotRunSelectorUI.Value)-273.15,'Color',self.Colours.orange);
                hold on
                plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Data(10,:,self.PlotRunSelectorUI.Value)-273.15,'Color',self.Colours.blue);
                plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Data(11,:,self.PlotRunSelectorUI.Value)-273.15,'Color',self.Colours.darkblue);
                hold off
                ylabel({'Temperature','(^{\circ}C)'});
                
                subplot(self.s{2});
                p{2} = plot(self.Model.Time(1,:,1),self.Model.Data(16,:,self.PlotRunSelectorUI.Value));
                ylabel({'Radiation','(W/m^2)'});
                
                subplot(self.s{3});
                p{3} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Data(12,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.yellow);
                ylabel({'Rock','(mol)'});
                
                subplot(self.s{4});
                Silicate_Weathering_Fraction = self.Model.Data(14,:,self.PlotRunSelectorUI.Value);
                Carbonate_Weathering_Fraction = self.Model.Data(15,:,self.PlotRunSelectorUI.Value);
                p{4} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),Silicate_Weathering_Fraction);
                hold on
                plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),Carbonate_Weathering_Fraction);
                ylabel({'Weathering',' Fraction',' '});
                hold off
                subplot(self.s{5});
                Silicate_Weathering = Silicate_Weathering_Fraction.*self.Model.Data(12,:,self.PlotRunSelectorUI.Value).*self.Model.Conditions.Constant.Silicate_Weatherability;
                Carbonate_Weathering = Carbonate_Weathering_Fraction.*self.Model.Data(13,:,self.PlotRunSelectorUI.Value).*self.Model.Conditions.Constant.Carbonate_Weatherability;
                
                Rivers = (2*(Silicate_Weathering+Carbonate_Weathering))/self.Model.Conditions.Constant.Riverine_Volume;
                p{5} = plot(self.Model.Time(1,:,1),Rivers);
                ylabel({'Rivers','(mol)'});
                
                xlabel('Time (yr)');
                set([self.s{1:4}],'XTick',[]);
                linkaxes([self.s{1:5}],'x');
                xlim([0,max(self.Model.Time(:,:,self.PlotRunSelectorUI.Value))]);
            elseif self.SubplotIndex==4;
                subplot(self.s{1});
                p{1} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Lysocline(:,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.blue);
                ylabel({'Lysocline','(m)'});
                set(gca,'YDir','Reverse');
                ylim([min(self.Model.Lysocline(:,:,self.PlotRunSelectorUI.Value))-500,max(self.Model.Lysocline(:,:,self.PlotRunSelectorUI.Value))+500]);
                
                subplot(self.s{2});
                p{2} = plot(self.Model.Conditions(self.PlotRunSelectorUI.Value).Constant.Hypsometric_Bin_Midpoints,self.Model.Seafloor(:,:,self.PlotRunSelectorUI.Value));
                ylabel({'Carbonate',' Distribution','(mol)'});
                set(gca,'XDir','Reverse');
                
                subplot(self.s{3});
                p{3} = plot(self.Model.Conditions(self.PlotRunSelectorUI.Value).Constant.Outgassing_Temporal_Resolution*(1:numel(self.Model.Outgassing(:,:,self.PlotRunSelectorUI.Value))),self.Model.Outgassing(:,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.red);
                ylabel({'Outgassing','(mol)'});
                
                subplot(self.s{4});
                p{4} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Seafloor_Total(1,:,self.PlotRunSelectorUI.Value));
                ylabel({'Seafloor Total','(mol)'});
            elseif self.SubplotIndex==3;
                subplot(self.s{1});
                p{1} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Data(17,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.cyan);
                ylabel({'Ice Mass','(mol)'});
                
                subplot(self.s{2});
                p{2} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Data(18,:,self.PlotRunSelectorUI.Value));
                ylabel({'Sea Level','(m)'}); 
                
                subplot(self.s{3});
                p{3} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Data(19,:,self.PlotRunSelectorUI.Value),'Color',self.Colours.darkgrey);
                ylabel({'Snow Line','(m)'});
                
                subplot(self.s{4});
                p{4} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Conditions.Present.PIC_Burial(2,:,self.PlotRunSelectorUI.Value));
                ylabel({'Deep','PIC Burial','(fraction)'});
                                   
%                 if self.Model.Conditions.Present.Carbonate_Surface_Sediment_Lock;
                    subplot(self.s{5});
                    p{5} = plot(self.Model.Time(1,:,self.PlotRunSelectorUI.Value),self.Model.Conditions.Present.PIC_Burial(1,:,self.PlotRunSelectorUI.Value));
                    ylabel({'Shallow','PIC Burial','(fraction)'});
                    ylim([0,1]);
                    set([self.s{1:4}],'XTick',[]);
                    linkaxes([self.s{1:5}],'x');
                
%                 else
%                     delete(self.s{5});
                    
%                     set([self.s{1:3}],'XTick',[]);
%                     linkaxes([self.s{1:4}],'x');
                
%                 end
                
                xlabel('Time (yr)');
                xlim([0,max(self.Model.Time(:,:,self.PlotRunSelectorUI.Value))]);
            
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
            if self.SubplotIndex == 1 || self.SubplotIndex==2 || self.SubplotIndex==3;
                self.s = cell(1,5);
                for n = 1:5;
                    self.s{n} = subplot(5,1,n,'Parent',self.Tab2Handle);
                end
            else
                delete(self.s{5});
                self.s = cell(1,4);
                for n = 1:4;
                    self.s{n} = subplot(4,1,n,'Parent',self.Tab2Handle);
                end
            end
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
        % Sets the output filepath
        function SetOutputFilename(self,src,event);
            self.OutputFilename = self.FilenameUI.String;
        end
        % Reads in a file and sets the attributes
        function SetInputFilepath(self,src,event);
            if isempty(self.FilenameUI.String);
                [InputFilename,InputFilepath] = uigetfile('*.nc','DefaultName','./../../../Results/');
            else
                [InputFilename,InputFilepath] = uigetfile('*.nc','DefaultName',self.FilepathUI.String);
            end
            if InputFilename~=0;
                self.InputFilepath = [InputFilepath,InputFilename];
                self.FileInputUI.String = self.InputFilepath;
                
%                 Model = ncreadatt(self.FileInputUI.String,'/','Model');
%                 Core = ncreadatt(self.FileInputUI.String,'/','Core');
%                 Solver = ncreadatt(self.FileInputUI.String,'/','Solver');
                
%                 self.ModelUI.Value = find(strcmp(self.ModelUI.String,Model));
%                 self.GetAvailableCores;
%                 self.CoreUI.Value = find(strcmp(self.CoreUI.String,Core));
%                 self.SolverUI.Value = find(strcmp(self.SolverUI.String,Solver));
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
                self.UpdateLogBox("Warning: File extension .nc added");
            else
                Ending = SplitFilename{end};
                if ~strcmp(Ending,'nc');
                    src.String = [SplitFilename{1:end-1},'.nc'];
                    self.UpdateLogBox("Warning: File extension changed to .nc");
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
                self.UpdateLogBox("Choose a model first");
            else
                self.Model = GECCO();
                % Prints to log box
                self.UpdateLogBox("Model instantiated");
                
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
            DirectoryContentsModelsFull = dir([self.ModelDirectory,'\..\..\*_Model*']);
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
                AvailableCoresFull = dir([self.ModelDirectory,'\..\..\',self.ModelUI.String{self.ModelUI.Value},'\Core\**\*.m']);
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
        function SelectSolverCallback(self,src,event);
            self.Model.Solver = self.SolverUI.String{self.SolverUI.Value};
            self.Model.SolverFcn = str2func(self.SolverUI.String{self.SolverUI.Value});
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
                    self.Runs = Run(Chunk([0,100000,20],[0,100000,100]));
                    self.Model.Conditions = Condition();
                % Otherwise use the inherent method
                else
                    self.Runs = self.Runs.AddRun([self.Runs(end).Chunks(1).TimeIn(1),self.Runs(end).Chunks(1).TimeIn(2),self.Runs(end).Chunks(1).TimeIn(3)],[self.Runs(end).Chunks(1).TimeOut(1),self.Runs(end).Chunks(1).TimeOut(2),self.Runs(end).Chunks(1).TimeOut(3)],self.Model);
                    self.Model.Conditions = self.Model.Conditions.AddCondition(self.Model.Conditions(end).Constant,self.Model.Conditions(end).Initial);
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
                Names = fieldnames(self.Model.Conditions(1).Constant);
                IsMatrix = contains(Names,'Matrix');
                Names = Names(~IsMatrix);
                [~,SortIndices] = sort(lower(Names));
%                 Names = fieldnames(self.Model.Conditions(1).Constant);
                self.ConstSelectorUI.String = Names(SortIndices);
                % Instantiates initial names
                self.InitSelectorUI.String = fieldnames(self.Model.Conditions(1).Initial);
            else
                % Otherwise error out
                self.UpdateLogBox("Error: Instantiate the model first");
            end
        end
        % Add a chunk
        function AddChunkCallback(self,src,event);
            % Error if no run is selected
            if isempty(self.SelectedRun);
                self.UpdateLogBox("Error: No run selected");
            else
                % Otherwise call the inherent method
                self.Runs(self.SelectedRun).AddChunk(Chunk([self.Runs(self.SelectedRun).Chunks(end).TimeIn(2),self.Runs(self.SelectedRun).Chunks(end).TimeIn(2)+(self.Runs(self.SelectedRun).Chunks(end).TimeIn(2)-self.Runs(self.SelectedRun).Chunks(end).TimeIn(1)),self.Runs(self.SelectedRun).Chunks(end).TimeIn(3)],[self.Runs(self.SelectedRun).Chunks(end).TimeOut(2),self.Runs(self.SelectedRun).Chunks(end).TimeOut(2)+((self.Runs(self.SelectedRun).Chunks(end).TimeOut(2)-self.Runs(self.SelectedRun).Chunks(end).TimeOut(1))),self.Runs(self.SelectedRun).Chunks(end).TimeOut(3)]));
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
                for Run_Index = 1:numel(self.Runs);
                    ChunkNumber = numel(self.Runs(Run_Index).Chunks);
                    for ChunkIndex = 1:ChunkNumber;
                        RunTable(Count,1) = Run_Index;
                        RunTable(Count,2) = ChunkIndex;
                        RunTable(Count,3:5) = self.Runs(Run_Index).Chunks(ChunkIndex).TimeIn;
                        RunTable(Count,6:8) = self.Runs(Run_Index).Chunks(ChunkIndex).TimeOut;
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
                
                self.Model.Conditions = [self.Model.Conditions(1:self.SelectedRun-1),self.Model.Conditions((self.SelectedRun+1):end)];
                
                % Rebuild the table
                self.RunTableUI.Data = self.BuildRunTable(src,event);
            else
                % Print to log
                self.UpdateLogBox("Error removing run");         
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
                            self.UpdateLogBox(["The chunks in Run ",num2str(RunIndex)," are not consecutive"]);
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
%             self.Model.Conditions.Initial(event.Indices(2)).Conditions = [self.Model.Conditions.Initial(event.Indices(2)).Atmosphere_CO2;
%                                                                           self.Model.Conditions.Initial(event.Indices(2)).Algae;
%                                                                           self.Model.Conditions.Initial(event.Indices(2)).Phosphate;
%                                                                           self.Model.Conditions.Initial(event.Indices(2)).DIC;
%                                                                           self.Model.Conditions.Initial(event.Indices(2)).Alkalinity;
%                                                                           self.Model.Conditions.Initial(event.Indices(2)).Atmosphere_Temperature;
%                                                                           self.Model.Conditions.Initial(event.Indices(2)).Ocean_Temperature;
%                                                                           self.Model.Conditions.Initial(event.Indices(2)).Silicate
%                                                                           self.Model.Conditions.Initial(event.Indices(2)).Carbonate;
%                                                                           self.Model.Conditions.Initial(event.Indices(2)).Silicate_Weathering_Fraction;
%                                                                           self.Model.Conditions.Initial(event.Indices(2)).Carbonate_Weathering_Fraction;
%                                                                           self.Model.Conditions.Initial(event.Indices(2)).Radiation;
%                                                                           self.Model.Conditions.Initial(event.Indices(2)).Ice];
        self.Model.Conditions.Undeal;
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
                self.UpdateLogBox("Please instantiate model first");
            elseif isempty(self.RunTableUI.Data);
                self.UpdateLogBox("No runs to load");
            else
                if isempty(self.FileInputUI.String);
                    self.SetInputFilepath;
                end
                InitMatrix = ncread(self.FileInputUI.String,'/Replication/Initial_Matrix');
                try
                    OutMatrix = ncread(self.FileInputUI.String,'/Replication/Initial_Outgassing');
                catch
                    OutMatrix = ncread(self.FileInputUI.String,'/Replication/Initial_Metamorphism');
                end
                if size(InitMatrix,2)<size(self.RunTableUI.Data,1);
                    self.UpdateLogBox("More runs than initial conditions");
                    for Run_Index = 1:size(self.InitMatrix,1);
                        self.Model.Conditions(Run_Index).Initial.Conditions = InitMatrix(:,Run_Index);
                        self.Model.Conditions(Run_Index).Deal;
                        
                        self.Model.Conditions(Run_Index).Initial.Outgassing = OutMatrix(:,Run_Index);
                    end 
                elseif size(InitMatrix,2)==size(self.RunTableUI.Data,1);
                    for Run_Index = 1:size(self.RunTableUI.Data,1);
                        self.Model.Conditions(Run_Index).Initial.Conditions = InitMatrix(:,Run_Index);
                        self.Model.Conditions(Run_Index).Deal;
                        
                        self.Model.Conditions(Run_Index).Initial.Outgassing = OutMatrix(:,Run_Index);
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
            for Run_Index = 1:numel(self.Model.Conditions);
                if size(self.Model.Conditions(Run_Index).Constant.(src.String{src.Value}),2)>1;
                    self.UpdateLogBox("Can't display matrices");
                    Table = '';
                else
                    Table(:,Run_Index) = self.Model.Conditions(Run_Index).Constant.(src.String{src.Value});
                end
            end
%             Table = horzcat(self.Model.Conditions.Constant(1:end).(src.String{src.Value}));
            self.ConstTableUI.Data = Table;
        end
        % Makes changes to the original constants ###Will fail when horzcat
        % stacks things greater than size 1 in the second dimension
        function ConstTableEditCallback(self,src,event);
            self.Model.Conditions(event.Indices(2)).Constant.(self.ConstSelectorUI.String{self.ConstSelectorUI.Value})(event.Indices(1),1) = event.NewData;
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
            for Run_Index = 1:numel(self.Runs);
                for ConstNumber = 1:numel(Fieldnames);
                    if strcmp(Fieldnames{ConstNumber},'PIC_Burial');
                        self.Model.Conditions(Run_Index).Constant.(Fieldnames{ConstNumber}) = Constants.(Fieldnames{ConstNumber})(:,end,Run_Index);
                    else
                        self.Model.Conditions(Run_Index).Constant.(Fieldnames{ConstNumber}) = Constants.(Fieldnames{ConstNumber})(:,:,Run_Index);
                    end
                end
            end
        end
        function LoadConstsCallback(self,src,event);
            Constants = LoadConstants(self,self.FileInputUI.String);
            AssignConstantsToModel(self,Constants);
            
            Variables = LoadVariables(self,self.FileInputUI.String);
            AssignVariablesToModel(self,Variables);
            
            % Update the constant table titles
            if exist('src','var');
                self.ExtendConstTableTitles(src,event);
            end
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
                self.UpdateLogBox("Unknown error in perturbation table update");
            end
        end
        function LoadPerts(self,src,event);
            Flag = 0;
            if isempty(self.Model);
                self.UpdateLogBox("Please instantiate model first");
            elseif isempty(self.RunTableUI.Data);
                self.UpdateLogBox("No runs to load");
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
                    self.UpdateLogBox("No perturbations to load");
                end
                if Flag==1;
                    self.UpdateLogBox("Some perturbations were skipped");
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
        % Sets the currently specified variables
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
                ConstNames = fieldnames(self.Model.Conditions(1).Constant);
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
                self.UpdateLogBox("Unexpected error with variable table");
            end
        end
        function LoadVars(self,src,event);
            if isempty(self.Model);
                self.UpdateLogBox("Please instantiate model first");
            elseif isempty(self.RunTableUI.Data);
                self.UpdateLogBox("No runs to load");
            else
                if isempty(self.FileInputUI.String);
                    self.SetInputFilepath;
                end
                VarMatrix = ncread(self.FileInputUI.String,'/Replication/Variable_Matrix');
                if size(VarMatrix,2)~=1;
                    for VMIndex = 1:size(VarMatrix,1);
                        CurrentVar = strsplit(strtrim(VarMatrix(VMIndex,:)),',');
                        if numel(CurrentVar)>3;
                            StringCat = [strcat(CurrentVar(3:end-1),','),CurrentVar(end)];
                            CurrentVar{3} = strcat([StringCat{:}]);
                            CurrentVar = CurrentVar(1:3);
                        end
                        self.Model.Conditions.AddVariable(CurrentVar{1},CurrentVar{2},CurrentVar{3});
                        self.VarTableUI.Data = [self.VarTableUI.Data;CurrentVar];
                    end
                else
                    self.UpdateLogBox("No variables to load");
                end
            end
        end
        function VarIDs = GetVarIDs(self,Filename);
            FileID = netcdf.open(Filename);
            VarGrpID = netcdf.inqNcid(FileID,'Variables');
            VarIDs = netcdf.inqVarIDs(VarGrpID);    
            netcdf.close(FileID);
        end
        function VarNames = GetVarNames(self,Filename);
            VarIDs = self.GetVarIDs(Filename);
            if ~isempty(VarIDs);
                FileID = netcdf.open(Filename);
                VarGrpID = netcdf.inqNcid(FileID,'Variables');
                for VarNumber = 1:numel(VarIDs);
                    [VarNames{VarNumber},~,~,~] = netcdf.inqVar(VarGrpID,VarIDs(VarNumber));
                end
                netcdf.close(FileID);
            else
                VarNames = [];
            end
        end
        function Variables = LoadVariables(self,Filename);
            VarIDs = self.GetVarIDs(Filename);
            VarNames = self.GetVarNames(Filename);
            if ~isempty(VarNames);
                FileID = netcdf.open(Filename);
                VarGrpID = netcdf.inqNcid(FileID,'Variables');
                for VarNumber = 1:numel(VarNames);
                    Variables.(VarNames{VarNumber}) = netcdf.getVar(VarGrpID,VarIDs(VarNumber));
                end
                
                netcdf.close(FileID);
            else
                Variables = [];
            end
        end
        function AssignVariablesToModel(self,Variables);
            if ~isempty(Variables);
                Fieldnames = fieldnames(Variables);
                for Run_Index = 1:numel(self.Runs);
                    for VarNumber = 1:numel(Fieldnames);
                        self.Model.Conditions(Run_Index).Constant.(Fieldnames{VarNumber}) = Variables.(Fieldnames{VarNumber})(:,end,Run_Index);
                    end
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
            for n = 1:numel(self.Model.Conditions);
                self.Model.Conditions(n).RmVariables;
            end
            
            for n = 1:size(self.VarTableUI.Data,1);
                
                Input1 = self.VarTableUI.Data{n,1};
                Input2 = str2double(self.VarTableUI.Data{n,2});
                Input3 = [self.VarTableUI.Data{n,3}];
                
                self.Model.Conditions.AddVariable(Input1,Input2,Input3);
            end
            
            
            
            self.CheckFileExists;
            self.OutputFile = [self.OutputFilepath,'\',self.OutputFilename];
            if strcmp(self.FilenameWarningUI.String,'File exists');
                delete(self.OutputFile);
            end
        end
        function Validate(self,src,event);
            self.ValidatedFlag = 0;
            Max_Outgassing_Tracked = self.Model.GetMaxOutgassing(self.Runs);
            Initial_Outgassing_Length = self.Model.GetInitialOutgassing(self.Runs);
            if numel(self.Runs)==0;
                self.UpdateLogBox("No run details provided");
%             elseif isempty(self.OutputFilepath) || isempty(self.OutputFilename);
%                 self.UpdateLogBox("Filename or filepath is empty");
            elseif sum(Max_Outgassing_Tracked==Initial_Outgassing_Length | Initial_Outgassing_Length==0 | Initial_Outgassing_Length==1 | Initial_Outgassing_Length==2)==0;
                self.UpdateLogBox(strcat("Initial Outgassing array is the wrong length, should be...",num2str(Max_Outgassing_Tracked)," elements"));
            else
                self.ValidatedFlag = 1;
            end
        end
        function CalculateDependents(self,src,event);
            % Number of timesteps
            for Run_Index = 1:numel(self.Runs);
                for Chunk_Index = 1:numel(self.Runs(Run_Index).Chunks);
                    Chunk_Step_Number{Run_Index}(Chunk_Index) = numel(self.Runs(Run_Index).Chunks(Chunk_Index).TimeIn(1):self.Runs(Run_Index).Chunks(Chunk_Index).TimeIn(3):self.Runs(Run_Index).Chunks(Chunk_Index).TimeIn(2));
                end
                Run_Step_Number(Run_Index) = sum(Chunk_Step_Number{Run_Index});
            end
            self.Model.dt = self.Runs(1).Chunks(1).TimeIn(3);
            self.Model.Total_Steps = Run_Step_Number;

            % Subduction
            for Run_Index = 1:numel(self.Runs);
                if self.Model.Conditions(Run_Index).Constant.Subduction_Spread ==0;
                    self.Model.Conditions(Run_Index).Present.Subduction_Gauss = 0;
                else
                    self.Model.Conditions(Run_Index).Present.Subduction_Gauss = (gaussmf(self.Model.Conditions(Run_Index).Constant.Hypsometric_Bin_Midpoints,[self.Model.Conditions(Run_Index).Constant.Subduction_Spread,-self.Model.Conditions(Run_Index).Constant.Subduction_Mean]))*self.Model.Conditions(Run_Index).Constant.Subduction_Risk;
                end
                
                if size(self.Model.Conditions(Run_Index).Initial.Seafloor,1)==2;
                    Xin = [0,self.Model.Conditions(Run_Index).Initial.Seafloor(1,:),10000];
                    Yin = [0,self.Model.Conditions(Run_Index).Initial.Seafloor(2,:),0];
                    Xi = self.Model.Conditions(Run_Index).Constant.BinMids;
                    
                    self.Model.Conditions(Run_Index).Initial.Seafloor = interp1(Xin,Yin,Xi);
                end
            end
            
            % Outgassing
            Max_Outgassing = self.Model.GetMaxOutgassing(self.Runs);
            for Run_Index = 1:numel(self.Runs);
                if self.Model.Conditions(Run_Index).Constant.Outgassing_Spread==0;
                    self.Model.Conditions(Run_Index).Present.Outgassing_Gauss = 0;
                else
                    self.Model.Conditions(Run_Index).Present.Outgassing_Gauss = gaussmf([-self.Model.Conditions(Run_Index).Constant.Outgassing_Spread*3:self.Model.Conditions(Run_Index).Constant.Outgassing_Temporal_Resolution:self.Model.Conditions(Run_Index).Constant.Outgassing_Spread*3],[self.Model.Conditions(Run_Index).Constant.Outgassing_Spread,0]);
                    self.Model.Conditions(Run_Index).Present.Outgassing_Gauss = (self.Model.Conditions(Run_Index).Present.Outgassing_Gauss/sum(self.Model.Conditions(Run_Index).Present.Outgassing_Gauss))';
                end
                
                if isempty([self.Model.Conditions(Run_Index).Initial.Outgassing]);
                    self.Model.Conditions(Run_Index).Initial.Outgassing = zeros(Max_Outgassing(Run_Index),1);
                elseif numel(self.Model.Conditions(Run_Index).Initial.Outgassing) == 1;
                    self.Model.Conditions(Run_Index).Initial.Outgassing = self.Model.Conditions(Run_Index).Initial.Outgassing.*ones(Max_Outgassing(Run_Index),1);
                elseif numel(self.Model.Conditions(Run_Index).Initial.Outgassing) == 2;
                    Vals = self.Model.Conditions(Run_Index).Initial.Outgassing;
                    self.Model.Conditions(Run_Index).Initial.Outgassing = NaN(Max_Outgassing(Run_Index),1);
                    Run_End = (self.Model.Conditions(Run_Index).Constant.Outgassing_Mean_Lag/self.Model.Conditions(Run_Index).Constant.Outgassing_Resolution);
                    Latest_NotYetFull_Metabox = Run_End-((4*(self.Model.Conditions(Run_Index).Constant.Outgassing_Spread/self.Model.Conditions(Run_Index).Constant.Outgassing_Resolution))/1);
                    Earliest_Empty_Metabox = Run_End+((4*(self.Model.Conditions(Run_Index).Constant.Outgassing_Spread/self.Model.Conditions(Run_Index).Constant.Outgassing_Resolution))/1);
                    
                    self.Model.Conditions(Run_Index).Initial.Outgassing(1:Latest_NotYetFull_Metabox-1) = Vals(1);
                    
                    Gauss = self.Model.Conditions(Run_Index).Constant.Outgassing_Gauss;
                    Half_Gauss = Gauss(floor(numel(Gauss)/2):end);
                    Scaled_Half_Gauss = Half_Gauss.*(Vals(1)/max(Half_Gauss));
                    Stretched_Scaled_Half_Gauss = interp1(1:numel(Scaled_Half_Gauss),Scaled_Half_Gauss,linspace(1,numel(Scaled_Half_Gauss),numel(6000:14000)))';
                    
                    self.Model.Conditions(Run_Index).Initial.Outgassing(6000:14000) = Stretched_Scaled_Half_Gauss;
                    
                    self.Model.Conditions(Run_Index).Initial.Outgassing(Earliest_Empty_Metabox+1:end) = Vals(2);
                
                end
            end
            % Weathering
            for Run_Index = 1:numel(self.Runs);
                self.Model.Conditions.Initial.Silicate_Weathering_Fraction = (self.Model.Conditions.Constant.Silicate_Weathering_Coefficient(1)*exp(self.Model.Conditions.Constant.Silicate_Weathering_Coefficient(2)*self.Model.Conditions.Initial.Atmosphere_Temperature))/2;
                self.Model.Conditions.Initial.Carbonate_Weathering_Fraction = (self.Model.Conditions.Constant.Carbonate_Weathering_Coefficient(1)*exp(self.Model.Conditions.Constant.Carbonate_Weathering_Coefficient(2)*self.Model.Conditions.Initial.Atmosphere_Temperature))/2;
           
                self.Model.Conditions(Run_Index).Initial.Conditions(14) = self.Model.Conditions.Initial.Silicate_Weathering_Fraction;
                self.Model.Conditions(Run_Index).Initial.Conditions(15) = self.Model.Conditions.Initial.Carbonate_Weathering_Fraction;
            end
            % Weathering
            for Run_Index = 1:numel(self.Runs);
                Silicate_Weathering = (self.Model.Conditions(Run_Index).Initial.Conditions(12)*self.Model.Conditions(Run_Index).Initial.Conditions(14));
                Carbonate_Weathering = (self.Model.Conditions(Run_Index).Initial.Conditions(13)*self.Model.Conditions(Run_Index).Initial.Conditions(15));
                
                Weathering = (Silicate_Weathering*self.Model.Conditions(Run_Index).Constant.Silicate_Weatherability + Carbonate_Weathering*self.Model.Conditions(Run_Index).Constant.Carbonate_Weatherability);

                self.Model.Conditions(Run_Index).Present.Riverine_Carbon = (Weathering.*2)./(self.Model.Conditions(Run_Index).Constant.Riverine_Volume);
                self.Model.Conditions(Run_Index).Present.Riverine_Alkalinity = self.Model.Conditions(Run_Index).Present.Riverine_Carbon;
            end
            
            Coefficients = GetCoefficients(self.Model.Conditions.Constant,self.Model.Conditions.Constant);
            [self.Model.Conditions.Present.CCKs,self.Model.Conditions.Present.CCK_Depth_Correction] = GetCCKConstants(self.Model.Conditions.Constant.Salinity,self.Model.Conditions.Initial.Ocean_Temperature,self.Model.Conditions.Constant.Pressure,self.Model.Conditions.Constant.Pressure_Correction,Coefficients);
            
            % pH
            for Run_Index = 1:numel(self.Runs);
                [self.Model.Conditions(Run_Index).Present.pH,self.Model.Conditions.Present.CO2,~,~,self.Model.Conditions.Present.OmegaC,~] = CarbonateChemistry_Iter(self.Model.Conditions.Constant,self.Model.Conditions.Initial.DIC,self.Model.Conditions.Initial.Alkalinity,[(10^(-8.0))*1000;(10^(-8.0))*1000],self.Model.Conditions.Present.CCKs);
                self.Model.Conditions(Run_Index).Present.HIn =  (10.^(-self.Model.Conditions(Run_Index).Present.pH))*1000;
            end
            
            % Lysocline
            self.Model.Conditions.Present.Lysocline = CalculateLysocline_Fun_RegulaFalsi_Full_Iter(self.Model,self.Model.Conditions.Initial.DIC(2),self.Model.Conditions.Initial.Ocean_Temperature);

        end
        %% Run
        function RunModel(self,src,event);
            drawnow;
            self.Validate(src,event);
            self.ValidateRuns(src,event);
            
            if self.ValidatedFlag;
                profile on;
                self.ColourBox.BackgroundColor = [1,1,0.5];
                self.Model.Conditions.Present = [];
                self.Finalise(src,event);
                self.Model.Conditions.UpdatePresent;
                self.CalculateDependents;
            
                
                DateTime(1) = datetime('now');
                self.UpdateLogBox(strcat("Starting..."," @ ",string(datetime('now','Format','HH:mm:ss'))));
               
                if ~isempty(self.OutputFilepath) && ~isempty(self.OutputFilename);
                    self.Model.PrepareNetCDF(self.OutputFile,self.Runs);
                    % Save the replication data
                    self.AddGroup(self.OutputFile);
                    self.DefineDimensions(self.OutputFile);
                    self.DefineVariables(self.OutputFile);
                    self.ProcessReplicatoryData;
                    self.AddReplicatoryData(self.OutputFile);
                end
                
                % Split the model
                ModelCells = self.Model.Split;
                % Parameter Redefinition
%                 for n = 1:numel(ModelCells);
%                     ModelCells{n}.Conditions.RedefineConstants;
%                     ModelCells{n}.Conditions.RedefineInitial;
%                     ModelCells{n}.Conditions.UpdatePresent;
%                     ModelCells{n}.CalculateDependents;
%                 end
                
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
                        Time_Out = (self.Runs(Run).Chunks(Chunk).TimeOut(1):self.Runs(Run).Chunks(Chunk).TimeOut(3):self.Runs(Run).Chunks(Chunk).TimeOut(2));
                        TimeChunks{Chunk} = Time_Out;
                        
                        % Create anonymous function
                        ODEFunc = eval(['@(t,y,y_Sub,y_Meta)',self.Model.CoreFcn,'(t,y,y_Sub,y_Meta,SingleRunModel)']);
                        
                        % Run the solver
                        [DataChunks{Chunk},ConstChunks{Chunk},LysChunks{Chunk},CoreChunks{Chunk},SeafloorChunks{Chunk},PICChunks{Chunk}] = self.Model.SolverFcn(ODEFunc,SingleRunModel,Time_In,Time_Out,SingleRunModel.Conditions.Initial.Conditions,SingleRunModel.Conditions.Initial.Seafloor,SingleRunModel.Conditions.Initial.Outgassing);
                        
                        % Reset the initial conditions
                        SingleRunModel.Conditions.Initial.Conditions = DataChunks{Chunk}(:,end);
                        SingleRunModel.Conditions.Deal;
                    end
                    
                    % Accumulate chunks into runs (as cells of cells)
                    DataRuns{Run} = horzcat(DataChunks{:});
                    TimeRuns{Run} = horzcat(TimeChunks{:});
                    ConstRuns{Run} = horzcat(ConstChunks{:});
                    LysRuns{Run} = horzcat(LysChunks{:});
                    CoreRuns{Run} = horzcat(CoreChunks{:});
                    SeafloorRuns{Run} = horzcat(SeafloorChunks{:});
                    PICRuns{Run} = horzcat(PICChunks{:});
                    
                    % Assign to model object
                    ModelCells{Run}.Data = DataRuns{Run};
                    ModelCells{Run}.Time = TimeRuns{Run};
                    ModelCells{Run}.Lysocline = LysRuns{Run};
                    ModelCells{Run}.AssignConstants(ConstRuns{Run});
                    ModelCells{Run}.Seafloor_Total = SeafloorRuns{Run};
                    ModelCells{Run}.Cores = CoreRuns{Run};
                    ModelCells{Run}.Conditions.Present.PIC_Burial = PICRuns{Run};
                    
                    % Display when run is complete
                    self.UpdateLogBox(strcat("Run number ",num2str(Run)," of ",num2str(numel(self.Runs))," complete @ ",string(datetime('now','Format','HH:mm:ss'))));
                    %                 fprintf(['\nRun number ',num2str(Run),' of ',num2str(numel(self.Runs)),' complete \n']);
                    
                    % Save data to file when each run is done
                    if ~isempty(self.OutputFilepath) && ~isempty(self.OutputFilename);
                        ModelCells{Run}.Save(self.OutputFile,Run);
                    end
                    
                    % Email
                    sendtheemail('ross.whiteford@soton.ac.uk','Model Run Complete',['Your model run saving to ',self.OutputFilepath,' finished at ',char(datetime('now','Format','HH:mm:ss'))])
                end
%                 catch ME
%                     self.UpdateLogBox('Error!');
%                 end
                  
                % Reconstitute the disparate data into the model object
                self.Model.Merge(ModelCells,self.Runs);
                
                % Print to log box
                self.UpdateLogBox("Successfully completed");

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
            for n = 1:size(self.VarTableUI.Data,1);
                if isempty(self.VarTableUI.Data{n,2});
                    %                 Dim_v2 = {'v_2',size(char(join(self.VarTableUI.Data([1,3:end]),',')),2)};
                    self.VarTableUI.Data{n,2} = ':';
                    %             else
                end
            end
            Dim_v2 = {'v_2',size(char(join(self.VarTableUI.Data,',')),2)};
%             end
            Dim_i2 = {'i_2',numel(self.Model.Conditions(1).Initial.Conditions)};
            
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
            
            CurrentDims = {'i_2','r'};
            netcdf.defVar(RepGrpID,'Initial_Matrix','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2})]);
            
            CurrentDims = {'m','r'};
            netcdf.defVar(RepGrpID,'Initial_Outgassing','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2})]);
            
            CurrentDims = {'k','r'};
            netcdf.defVar(RepGrpID,'Outgassing_End','double',[netcdf.inqDimID(FileID,CurrentDims{1}),netcdf.inqDimID(FileID,CurrentDims{2})]);
            
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
            if size(self.VarTableUI.Data,1)>0 && isempty(self.VarTableUI.Data{2});
                self.VarMatrix = char(join(self.VarTableUI.Data([1,3:end]),','));
            else
                self.VarMatrix = char(join(self.VarTableUI.Data,','));
            end
            for Run_Index = 1:numel(self.Model.Conditions);
                self.InitMatrix(:,Run_Index) = self.Model.Conditions(Run_Index).Initial.Conditions;
            end
        end
        function AddReplicatoryData(self,Filename);
            FileID = netcdf.open(Filename,'WRITE');
            RepGrpID = netcdf.inqNcid(FileID,'Replication');
            
            Run_MatrixID = netcdf.inqVarID(RepGrpID,'Run_Matrix');
            netcdf.putVar(RepGrpID,Run_MatrixID,self.RunMatrix);
            
            Init_MatrixID = netcdf.inqVarID(RepGrpID,'Initial_Matrix');
            netcdf.putVar(RepGrpID,Init_MatrixID,self.InitMatrix);
            
            Init_MetaID = netcdf.inqVarID(RepGrpID,'Initial_Outgassing');
            MaxMeta = self.Model.GetMaxOutgassing(self.Runs);
            Initial_Outgassing = NaN(max(MaxMeta),numel(MaxMeta));
            for Run_Index = 1:numel(self.Runs);
                Initial_Outgassing(1:MaxMeta(Run_Index),Run_Index) = self.Model.Conditions(Run_Index).Initial.Outgassing;
            end
            netcdf.putVar(RepGrpID,Init_MetaID,Initial_Outgassing);
            
            Meta_EndID = netcdf.inqVarID(RepGrpID,'Outgassing_End');
            Outgassing_End = self.Model.GetOutgassingEnd(self.Runs);
            netcdf.putVar(RepGrpID,Meta_EndID,Outgassing_End);
            
            
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
            
            % Instantiates constant names
            self.ConstSelectorUI.String = fieldnames(self.Model.Conditions(1).Constant);
            % Instantiates initial names
            self.InitSelectorUI.String = fieldnames(self.Model.Conditions(1).Initial);
        end
        function FullCopyWrapper(self,src,event);
            if isempty(self.FileInputUI.String);
                self.UpdateLogBox("Please select an input file");
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
        function Time = LoadTime(self,Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            TimeID = netcdf.inqVarID(DataGrpID,'Time');
            Time = netcdf.getVar(DataGrpID,TimeID);
            netcdf.close(FileID);
        end
        function Lysocline = LoadLysocline(self,Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            LysID = netcdf.inqVarID(DataGrpID,'Lysocline');
            Lysocline = netcdf.getVar(DataGrpID,LysID); 
            netcdf.close(FileID);
        end
        function Data = LoadData(self,Filename);
            DataNames = self.Model.DataNames;
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            Data = [];
            for DataNumber = 1:numel(DataNames);
                DataID = netcdf.inqVarID(DataGrpID,DataNames{DataNumber});
                DataCell{DataNumber} = netcdf.getVar(DataGrpID,DataID);
            end
            if numel(DataCell{9})==1000;
                DataID = netcdf.inqVarID(DataGrpID,'Terrestrial_Carbonate');
                DataCell{9} = netcdf.getVar(DataGrpID,DataID);
            end
            Data =  vertcat(DataCell{:});
            netcdf.close(FileID);
        end
        function Seafloor = LoadSea(self,src,event);
            FileID = netcdf.open(self.FileInputUI.String);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            try
                SeafloorID = netcdf.inqVarID(DataGrpID,'Seafloor');
            catch
                SeafloorID = netcdf.inqVarID(DataGrpID,'Carbonate');
            end
            Seafloor = netcdf.getVar(DataGrpID,SeafloorID);
            self.Model.Conditions.Initial.Seafloor = Seafloor;
            netcdf.close(FileID);
        end
        function Seafloor = LoadSeafloor(self,Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            try
                SeafloorID = netcdf.inqVarID(DataGrpID,'Seafloor');
            catch
                SeafloorID = netcdf.inqVarID(DataGrpID,'Carbonate');
            end
            Seafloor = netcdf.getVar(DataGrpID,SeafloorID);
            netcdf.close(FileID);
        end
        function SeafloorTotal = LoadSeafloorTotal(self,Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            try
                SeafloorTotalID = netcdf.inqVarID(DataGrpID,'Seafloor_Total');
            catch
                SeafloorTotalID = NaN;
            end
            if ~isnan(SeafloorTotalID);
                SeafloorTotal = netcdf.getVar(DataGrpID,SeafloorTotalID);
            else
                SeafloorTotal = NaN;
            end
            netcdf.close(FileID);
        end
        function PICBurial = LoadPICBurial(self,Filename);
            FileID = netcdf.open(Filename);
            ConstGrpID = netcdf.inqNcid(FileID,'Constants');
            PICBurialID = netcdf.inqVarID(ConstGrpID,'PIC_Burial');
            PICBurial = netcdf.getVar(ConstGrpID,PICBurialID);
            netcdf.close(FileID);
        end
        function Carbonate_Surface_Sediment_Lock = LoadLock(self,Filename);
            FileID = netcdf.open(Filename);
            ConstGrpID = netcdf.inqNcid(FileID,'Constants');
            LockID = netcdf.inqVarID(ConstGrpID,'Carbonate_Surface_Sediment_Lock');
            Carbonate_Surface_Sediment_Lock = netcdf.getVar(ConstGrpID,LockID);
            netcdf.close(FileID);
        end
        function Cores = LoadCores(self,Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            CoresID = netcdf.inqVarID(DataGrpID,'Cores');
            Cores = netcdf.getVar(DataGrpID,CoresID);
            netcdf.close(FileID);
        end
        function Outgassing = LoadOutgassing(self,Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            OutgassingID = netcdf.inqVarID(DataGrpID,'Outgassing');
            Outgassing = netcdf.getVar(DataGrpID,OutgassingID);
            netcdf.close(FileID);
        end
        function Metamorphism = LoadMetamorphism(self,Filename);
            FileID = netcdf.open(Filename);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            MetamorphismID = netcdf.inqVarID(DataGrpID,'Metamorphism');
            Metamorphism = netcdf.getVar(DataGrpID,MetamorphismID);
            netcdf.close(FileID);
        end
        function LoadOut(self,src,event);
            FileID = netcdf.open(self.FileInputUI.String);
            DataGrpID = netcdf.inqNcid(FileID,'Data');
            try
                OutID = netcdf.inqVarID(DataGrpID,'Outgassing');
            catch
                OutID = netcdf.inqVarID(DataGrpID,'Metamorphism');
            end
            Outgassing = netcdf.getVar(DataGrpID,OutID);
            
            RepGrpID = netcdf.inqNcid(FileID,'Replication');
            try
                OutEndID = netcdf.inqVarID(RepGrpID,'Outgassing_End');
            catch
                OutEndID = netcdf.inqVarID(RepGrpID,'Metamorphism_End');
            end
            Out_End = netcdf.getVar(RepGrpID,OutEndID);
            MaxOut = self.Model.GetMaxOutgassing(self.Runs);
            
            if MaxOut-numel(Outgassing((Out_End+1):end))>=0;
                self.Model.Conditions.Initial.Outgassing = padarray(Outgassing((Out_End+1):end),MaxOut-numel(Outgassing((Out_End+1):end)),'post');
            else
                self.Model.Conditions.Initial.Outgassing = Outgassing((numel(Outgassing)-MaxOut+1):end);
            end
            netcdf.close(FileID);
        end
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
        function LoadFinal(self,src,event);
            if isempty(self.FileInputUI.String);
                self.UpdateLogBox("Please select an input file");
            elseif isempty(self.Model);
                self.UpdateLogBox("Please instantiate the model first");
            else
                Data = self.LoadData(self.FileInputUI.String);
                if numel(self.Runs)==size(Data,3);
                    for RunNumber = 1:numel(self.Runs);
                        self.Model.Conditions(RunNumber).Initial.Conditions = Data(:,end,RunNumber);
                        Lysocline = self.LoadLysocline(self.FileInputUI.String);
                        self.Model.Conditions(RunNumber).Present.Lysocline = Lysocline(end);            
                    end
                elseif numel(self.Runs)>size(Data,3);
                    for RunNumber = 1:numel(self.Runs);
                        self.Model.Conditions.Initial(RunNumber).Conditions = Data(end,:,1);
                    end
                    self.UpdateLogBox("More runs than initial conditions, used output from run 1");
                elseif numel(self.Runs)<size(Data,3);
                    for RunNumber = 1:numel(self.Runs);
                        self.Model.Conditions.Initial(RunNumber).Conditions = Data(end,:,RunNumber);
                    end
                    self.UpdateLogBox("More initial conditions than runs");
                end
                self.Model.Conditions.Deal;
            end
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
        %% Log box
        function UpdateLogBox(self,Message);
            if ~isempty(self.LogBoxUI.String);
                self.LogBoxUI.String = [self.LogBoxUI.String;Message];
            else
                self.LogBoxUI.String = Message;
            end
            LogBoxObj = findjobj(self.LogBoxUI);
            LogBoxEdit = LogBoxObj.getComponent(0).getComponent(0);
            LogBoxEdit.setCaretPosition(LogBoxEdit.getDocument.getLength);
            drawnow;
        end
    end
end
