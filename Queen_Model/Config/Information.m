classdef Information < handle
    properties
        Model_Name = "Queen";
        Version_Number = 0.2;
        Version_Codename = "House";
        Output_Filepath = "";
        Output_Filename = "";
        Output_File = "";
        Input_File = "";
    end
    properties (Hidden=true)
        ModelDirectory
        InstalledModels
    end
    methods
        function self = Information();
        end       
        
        %%
        function SortOutFilepath(self);
            if ~isempty(self);
                if ~strcmp(self.Output_Filename,"") && strcmp(self.Output_Filepath,"");
                    self.Output_Filepath = ".";
                end
                if ~strcmp(self.Output_Filepath,"") && ~strcmp(self.Output_Filepath,"");
                    self.Output_File = strcat(self.Output_Filepath,"\",self.Output_Filename);
                end
            end
        end
        function Load(self,Filename);
            Properties = fieldnames(self);
            for Property_Index = 1:numel(Properties);
                self.(Properties{Property_Index}) = [];
            end
            
            self.Model_Name = ncreadatt(Filename,'/','Model');
            self.Version_Number = ncreadatt(Filename,'/','Version_Number');
            self.Version_Codename = ncreadatt(Filename,'/','Version_Codename');
        end
        
    end
end