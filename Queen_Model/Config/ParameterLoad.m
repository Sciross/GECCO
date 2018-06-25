classdef ParameterLoad < handle
    properties
    end
    methods
        function Retrieved_Data = LoadIndividual(self,Filename,Individual,Indices);
            % Check against string input (what happens if another type is
            % used?)
            if ~ischar(Individual);
                Individual = char(Individual);
            end
            
            % Deal with the Index            
            FileID = netcdf.open(Filename,'NOWRITE');
            ParamGrpID = netcdf.inqNcid(FileID,'Parameters');
            if strcmp(class(self),"CarbonateChemistry");
                ParamSubGrpID = netcdf.inqNcid(ParamGrpID,'Carbonate_Chemistry');
            else
                ParamSubGrpID = netcdf.inqNcid(ParamGrpID,class(self));
            end
            try
                VarID = netcdf.inqVarID(ParamSubGrpID,Individual);
            catch
                warning(strcat("Parameter '",string(Individual),"' not found"));
                Retrieved_Data = [];
                return;
            end
            [~,~,DimIDs,~] = netcdf.inqVar(ParamSubGrpID,VarID);
            [Dim_Names,Dim_Sizes] = GECCO.DimIDToDim(FileID,DimIDs);
            
            % Process Index
            if nargin<4;
                Indices = {':',':',':',':'};
            elseif numel(Indices)==1;
                Indices = {Indices,Indices,Indices,Indices};                
            end
            
            % Special case
            if strcmp(Individual,"PIC_Burial");
                Indices{2} = "end";
            end
            
            % Change indices to matrix
            if iscell(Indices);
                for Indices_Index = 1:numel(Indices);
                    if isnumeric(Indices{Indices_Index});
                        if Indices<Dim_Sizes(Indices_Index);
                            Start(Indices_Index) = Indices{Indices_Index};
                        else                            
                            netcdf.close(FileID);
                            error("The index was longer than the variable");
                        end
                    else
                        if strcmp(Indices{Indices_Index},':');                    
                            Start(Indices_Index) = 0;
                        elseif strcmp(Indices{Indices_Index},'end');
                            Start(Indices_Index) = Dim_Sizes(Indices_Index)-1;
                        else
                            netcdf.close(FileID);
                            error("The index string was not understood");
                        end                        
                    end                    
                end
            end
            Count = Dim_Sizes-Start;
            
            Retrieved_Data = netcdf.getVar(ParamSubGrpID,VarID,Start,Count);
            netcdf.close(FileID);
        end
        function Retrieved_Data = LoadIndividualPerturbations(self,Filename,Individual,Indices);
            % Check against string input (what happens if another type is
            % used?)
            if ~ischar(Individual);
                Individual = char(Individual);
            end
            
            % Deal with the Index            
            FileID = netcdf.open(Filename,'NOWRITE');
            ParamGrpID = netcdf.inqNcid(FileID,'Perturbations');
            ParamSubGrpID = netcdf.inqNcid(ParamGrpID,class(self));
            try
                VarID = netcdf.inqVarID(ParamSubGrpID,Individual);
            catch
%                 warning(strcat("Parameter '",string(Individual),"' not found"));
                Retrieved_Data = {};
                return;
            end
            [~,~,DimIDs,~] = netcdf.inqVar(ParamSubGrpID,VarID);
            [Dim_Names,Dim_Sizes] = GECCO.DimIDToDim(FileID,DimIDs);
            
            % Process Index
            if nargin<4;
                Indices = {':',':',':',':'};
            elseif numel(Indices)==1;
                Indices = {Indices,Indices,Indices,Indices};                
            end
            
            % Change indices to matrix
            if iscell(Indices);
                for Indices_Index = 1:numel(Indices);
                    if isnumeric(Indices{Indices_Index});
                        if Indices<Dim_Sizes(Indices_Index);
                            Start(Indices_Index) = Indices{Indices_Index};
                        else                            
                            netcdf.close(FileID);
                            error("The index was longer than the variable");
                        end
                    else
                        if strcmp(Indices{Indices_Index},':');                    
                            Start(Indices_Index) = 0;
                        elseif strcmp(Indices{Indices_Index},'end');
                            Start(Indices_Index) = Dim_Sizes(Indices_Index)-1;
                        else
                            netcdf.close(FileID);
                            error("The index string was not understood");
                        end                        
                    end                    
                end
            end
            Count = Dim_Sizes-Start;
            
            Retrieved_Data = netcdf.getVar(ParamSubGrpID,VarID,Start,Count);
            Trimmed_Data = Retrieved_Data(double(Retrieved_Data)~=0)';
            Split_Data = strsplit(Trimmed_Data,"\\t");
            Split_Data{end} = strrep(Split_Data{end},'@(Conditions)','');
            if strcmp(class(self),"Output");
                Type = 'Initials';
            else
                Type = 'Constants';
            end
            Additional_Data = {Type,class(self),Individual};
            Retrieved_Data = [Split_Data(1),Additional_Data,Split_Data(2:end)];
            netcdf.close(FileID);
        end
        function Retrieved_Data = LoadIndividualTransients(self,Filename,Individual,Indices);
            % Check against string input (what happens if another type is
            % used?)
            if ~ischar(Individual);
                Individual = char(Individual);
            end
            
            % Deal with the Index            
            FileID = netcdf.open(Filename,'NOWRITE');
            ParamGrpID = netcdf.inqNcid(FileID,'Transients');
            ParamSubGrpID = netcdf.inqNcid(ParamGrpID,class(self));
            try
                VarID = netcdf.inqVarID(ParamSubGrpID,Individual);
            catch
%                 warning(strcat("Parameter '",string(Individual),"' not found"));
                Retrieved_Data = {};
                return;
            end
            [~,~,DimIDs,~] = netcdf.inqVar(ParamSubGrpID,VarID);
            [Dim_Names,Dim_Sizes] = GECCO.DimIDToDim(FileID,DimIDs);
            
            % Process Index
            if nargin<4;
                Indices = {':',':',':',':'};
            elseif numel(Indices)==1;
                Indices = {Indices,Indices,Indices,Indices};                
            end
            
            % Change indices to matrix
            if iscell(Indices);
                for Indices_Index = 1:numel(Indices);
                    if isnumeric(Indices{Indices_Index});
                        if Indices<Dim_Sizes(Indices_Index);
                            Start(Indices_Index) = Indices{Indices_Index};
                        else                            
                            netcdf.close(FileID);
                            error("The index was longer than the variable");
                        end
                    else
                        if strcmp(Indices{Indices_Index},':');                    
                            Start(Indices_Index) = 0;
                        elseif strcmp(Indices{Indices_Index},'end');
                            Start(Indices_Index) = Dim_Sizes(Indices_Index)-1;
                        else
                            netcdf.close(FileID);
                            error("The index string was not understood");
                        end                        
                    end                    
                end
            end
            Count = Dim_Sizes-Start;
            
            Retrieved_Data = netcdf.getVar(ParamSubGrpID,VarID,Start,Count);
            Trimmed_Data = Retrieved_Data(double(Retrieved_Data)~=0)';
            Split_Data = strsplit(Trimmed_Data,"\\t");
            Split_Data{end} = strrep(Split_Data{end},'@(t,Conditions)','');
%             Type = 'Constants';
            Additional_Data = {class(self),Individual};
            Retrieved_Data = [Split_Data(1),Additional_Data,Split_Data(2:end)];
            
            netcdf.close(FileID);
        end
        function Load(self,Filename,Run_Index);
            Properties = properties(self);
            for Properties_Index = 1:numel(Properties);
                Property_Data = self.LoadIndividual(Filename,Properties{Properties_Index},":");
                if ~isempty(Property_Data);
                    self.(Properties{Properties_Index}) = Property_Data;
                end
            end
        end
        function LoadPerturbations(self,Filename,Run_Index);
            Properties = properties(self);
            if nargin<3;
                Run_Index = ':';
            end
            for Properties_Index = 1:numel(Properties);
                Property_Data = self.LoadIndividualPerturbations(Filename,Properties{Properties_Index},Run_Index);
                self.(Properties{Properties_Index}) = Property_Data;
            end
        end
        function LoadTransients(self,Filename,Run_Index);
            Properties = properties(self);
            for Properties_Index = 1:numel(Properties);
                Property_Data = self.LoadIndividualTransients(Filename,Properties{Properties_Index});
                self.(Properties{Properties_Index}) = Property_Data;
            end
        end       
    end
end