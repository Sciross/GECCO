function Output = RunCode(Runs,Model);
    %% Run code
    Model.Conditions.RedefineConstants;
    Model.Conditions.RedefineInitial;
    Model.Conditions.UpdatePresent;
    Model.CalculateDependents;
    
    RunNumber = numel(Runs);
                
    % Parallel loop for runs
    for Run = 1:RunNumber;        
        % Preallocate output arrays
        DataChunks = cell(1:numel(Runs(Run).Chunks));
        TimeChunks = cell(1:numel(Runs(Run).Chunks));
        ConstChunks = cell(1:numel(Runs(Run).Chunks));
        LysChunks = cell(1:numel(Runs(Run).Chunks));
        
        % Loop for each chunk
        for Chunk = 1:numel(Runs(Run).Chunks);
            % Apply the relevant perturbations on a per model-run basis
            Model.Conditions.Perturb({Runs(Run).Perturbations;Runs(Run).Chunks(Chunk).Perturbations});
            
            % Separate and save the time data
            Time_In = Runs(Run).Chunks(Chunk).TimeIn(1):Runs(Run).Chunks(Chunk).TimeIn(3):Runs(Run).Chunks(Chunk).TimeIn(2);
            Time_Out = (Runs(Run).Chunks(Chunk).TimeOut(1):Runs(Run).Chunks(Chunk).TimeOut(3):Runs(Run).Chunks(Chunk).TimeOut(2))';

            TimeChunks{Chunk} = Time_Out;
            
            % Create anonymous function
            ODEFunc = eval(['@(t,y)',Model.CoreFcn,'(t,y,Model)']);
            
            % Run the solver
            [DataChunks{Chunk},ConstChunks{Chunk},LysChunks{Chunk}] = Model.SolverFcn(ODEFunc,Time_In,Model.Conditions.Initial.Conditions,Time_Out,Model);
            
            % Reset the initial conditions
            Model.Conditions.Initial.Conditions = DataChunks{Chunk}(end,:);
            Model.Conditions.Deal(Run);
        end
        
        % Accumulate chunks into runs (as cells of cells)
        DataRuns{Run} = vertcat(DataChunks{:});
        TimeRuns{Run} = vertcat(TimeChunks{:});
        ConstRuns{Run} = vertcat(ConstChunks{:});
        LysRuns{Run} = vertcat(LysChunks{:});
        
        % Assign to model object
        Model{Run}.Data = DataRuns{Run};
        Model{Run}.Time = TimeRuns{Run};
        Model{Run}.Lysocline = LysRuns{Run};
        Model{Run}.AddConst(ConstRuns{Run});
        
        % Display when run is complete
        self.LogBoxUI.String = [self.LogBoxUI.String;['Run number ',num2str(Run),' of ',num2str(numel(self.Runs)),' complete']];
        %                 fprintf(['\nRun number ',num2str(Run),' of ',num2str(numel(self.Runs)),' complete \n']);
        
        % Save data to file when each run is done
        Model{Run}.Save(self.OutputFile,Run);
    end

end