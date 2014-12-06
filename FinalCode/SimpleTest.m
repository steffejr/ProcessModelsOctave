addpath /home/steffejr/Scripts/psom
addpath /home/steffejr/Scripts/ProcessModelsOctave/FinalCode

Nvoxels = 50;
NSub = 100;
X = round(rand(NSub,1));
a = 0.5;
M = a.*repmat(X,1,Nvoxels) + randn(NSub,Nvoxels);
b = 0.5;
cP = 0.5;
Y = cP.*X + b.*M(:,4) + randn(NSub,1);

corr([X M Y]);
BaseDir = '/home/steffejr/Scripts/TestThings';

data = {};
data{1} = X;
data{2} = M;
data{3} = Y;

Names = {};
Names{1} = 'A';
Names{2} = 'B';
Names{3} = 'C';

Nvar = length(data);

Nboot = 100;

Nperm = 0;

NJobSplit = 10;

Thresh = [0.05];

% Create a structure which will contain all information for this analysis.
ModelInfo = {};
ModelInfo.BaseDir = BaseDir;
ModelInfo.Names = Names;
ModelInfo.data = data;
ModelInfo.Nboot = Nboot;
ModelInfo.Nperm = Nperm;
ModelInfo.BaseDir = BaseDir;

ModelInfo.Indices = 1;
ModelInfo.NJobSplit = NJobSplit;
ModelInfo.Thresholds = Thresh;
ModelInfo.STRAT = [];
ModelInfo.Nsub = size(data{1},1);
ModelInfo.Nvar = Nvar;
ModelInfo.Nvoxels = Nvoxels;

% Prepare the output data header
DataHeader.fname = '';
DataHeader.descrip = '';
DataHeader.dt = [16 0];
ModelInfo.DataHeader = DataHeader;

Model1 = ModelInfo;

% Name of the output folder
Tag = 'ExampleModel1_boot';
Model1.Tag = Tag;

Direct = zeros(Model1.Nvar);
Direct(1,[2 3]) = 1;
Direct(2,3) = 1;

Inter = zeros(Model1.Nvar);
Paths = zeros(Model1.Nvar);
Paths(1,2) = 1;
Paths(2,3) = 2;


Model1.Direct = Direct;
Model1.Inter = Inter;
Model1.Paths = Paths;

%%
[pipeline, Model1] =  PrepareDataForPSOM(Model1)
SubmitPSOMPipeline(pipeline,Model1)
<<<<<<< HEAD

=======
>>>>>>> origin

