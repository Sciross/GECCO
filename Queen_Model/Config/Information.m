classdef Information < handle
    properties
        Model_Name = "Queen";
        Version_Number = 0.2;
        Version_Codename = "House";
        OutputFilepath = "";
        OutputFilename = "";
        OutputFile = "";
        InputFile = "";
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
            if ~strcmp(self.OutputFilename,"") && strcmp(self.OutputFilepath,"");
                self.OutputFilepath = ".";
            end
            if ~strcmp(self.OutputFilepath,"") && ~strcmp(self.OutputFilepath,"");
                self.OutputFile = strcat(self.OutputFilepath,"\",self.OutputFilename);
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