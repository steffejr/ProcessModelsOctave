function OutFolder = PrepareDataForProcess(ModelInfo)
% In order for this program to work in both a cluster environment and a
% single computer environment the data is saved and the analysis programs
% are given a path name. The data specified by the path is then loaded, the
% data analyzed and the results saved. WHen using a cluster environment the
% data can be split into chunks and multiple function calls are sent to teh
% cluster with each provided a path to a different chunk of data. Instead
% of passing data to each function call on the cluster, only the paths are
% passed.
%

% To Do:
% This function checks the specified model to ensure it is correctly
% specified. It also sets up the output folder structure for housing
% results. This is especially important for working with a cluster
% environment.
%

% The folder for housing these analyses uses the provided Tag name along
% with the current date and time.
c = clock;

% Create the output folder name
OutFolderName = sprintf('%s_%s_%02d-%02d',ModelInfo.Tag,date,c(4),c(5));

% Create the full output folder name
OutFolder = fullfile(ModelInfo.BaseDir,OutFolderName);

% Actually create the folders if they do not exist already.
if ~exist(OutFolder)
    mkdir(OutFolder);
end

% Create a folder to store the data in
DataFolder = fullfile(OutFolder,'data');
if ~exist(DataFolder)
    mkdir(DataFolder);
end

% Is this a bootstrap analysis or a permutation analysis?
if ModelInfo.Nboot > 0 && ModelInfo.Nperm > 0
    errordlg('The model can apply bootstrapping OR permutation testing NOT both.');
elseif ModelInfo.Nboot > 0
    ModelType = 'bootstrap';
elseif ModelInfo.Nperm > 0
    ModelType = 'permutation';
end

% Is this analysis using the cluster?
if ModelInfo.NJobSplit > 1
    % Since this analysis will use the cluster then setup the folders to
    % hold the job files and their output
    % Create the folder to hold the output from the jobs executed on the
    % cluster. These are especially useful for investigation of errors.
    JobOutputFolder = fullfile(OutFolder,'JobOutput');
    if ~exist(JobOutputFolder,'dir')
        mkdir(JobOutputFolder);
    end
    
    % Create the folder to hold the job files that get sent to the cluster
    % itself. These are useful if any jobs
    InJobFolder = fullfile(OutFolder,'JobFiles');
    if ~exist(InJobFolder,'dir')
        mkdir(InJobFolder);
    end
    
    switch ModelType
        case 'bootstrap'
            % For some reason the cd is causing problems!
            cd(JobOutputFolder)
            % Here the data is split and saved as a series of small files.
            
            
            % How many voxels will be in each split?
            % Note that the ceil function rounds UP. So after hundreds of
            % jobs there may not NEED to be 500 jobs but only 498.
            NvoxelsPerJob = ceil(ModelInfo.Nvoxels/ModelInfo.NJobSplit);
            
            % Cycle over the number of splits and submit each data chunk to
            % the cluster to be processed.
            % Create a list of submitted jobs to be used for executing
            % clean up commands after the jobs have finished.
            WaitList = '';
            % This counter is used because sometimes the final job(s) does
            % not have any voxels in it vbecause of the ceil round
            % performed just above.
            ActualNJobSplit = 0;
            for i = 1:ModelInfo.NJobSplit
                
                VoxelsForThisJob = [(i-1)*NvoxelsPerJob + 1:i*NvoxelsPerJob];
                
                
                % remove any voxels in this split which are beyond the
                % total number of voxels in the dataset. This is only a
                % concern for the last data split which may be a partial
                % smaller data set.
                VoxelsForThisJob(find(VoxelsForThisJob > ModelInfo.Nvoxels)) = [];
                
                % Check to see if this list is empty
                if ~isempty(VoxelsForThisJob)
                    ActualNJobSplit = ActualNJobSplit + 1;
                    % Create a version of the full data/model structure only containing the
                    % subset of voxels to be analyzed.
                    subModelInfo = ModelInfo;
                    subModelInfo.Indices = VoxelsForThisJob;
                    for j = 1:ModelInfo.Nvar
                        % Check to see which variables are multi-voxel variables and
                        % extract the subset of data
                        if size(subModelInfo.data{j},2) > 1
                            subModelInfo.data{j} = ModelInfo.data{j}(:,VoxelsForThisJob);
                        end
                    end
                    % Save this subset of data to a file
                    InTag = sprintf('data_%04d',i);
                    InDataPath = fullfile(DataFolder,InTag);
                    Str = ['save ' InDataPath ' subModelInfo  '];
                    eval(Str);
                    
                    % Create the cluster submission job
                    jobPath = fullfile(InJobFolder,sprintf('job_%04d.sh',i));
                    fid = fopen(jobPath,'w');
                    % Create string of the command to be run with MatLab
                    Command = sprintf('Results = CycleOverVoxelsProcessBootstrap(''%s'');',InDataPath);
                    % Create the cluster submission script
                    CreateClusterJobFile(Command,fid)
                    % Submit the script to the cluster
                    [JobName,ClusterCommand] = SubmitClusterJob(jobPath,JobOutputFolder);
                    fprintf(1,'%s\n',ClusterCommand);
                    
                    % Replace this with the tools from FieldTrip
                    %[JobName, puttime] = qsubfeval('CycleOverVoxelsProcessBootstrap',InDataPath,'memreq',1024^3,...
                    %    'timreq',24*60*60,'matlabcmd','/usr/local/MATLAB/R2013b/bin/matlab',...
                    %    'jvm','no','queue','veryshort.q');
                    
                    
                    % Add job to wait list
                    WaitList = sprintf('%s,%s',WaitList,JobName);
                end
            end
            % Remove initial comma from the WaitList
            WaitList = WaitList(2:end);
            % The following command is submitted to the cluster and given a
            % list of all the previous processing jobs. This forces the
            % write out of the resultant images to
            % wait for all of the other jobs to finish first. These
            % clean up commands and writing out the images do not need to be
            % run on the cluster.
            % The advantage of using the cluster queueing is that this job
            % waits until other jobs finish. By having the cluster wait
            % it frees up the MatLab process on the head node.
            %
            % Write out the resultant images
            Command = sprintf('WriteOutResults(''%s'')',OutFolder);
            jobPath = fullfile(InJobFolder,sprintf('WriteOutJob.sh'));
            fid = fopen(jobPath,'w');
            CreateClusterJobFile(Command,fid)
            % Submit the job with the wait list.
            SubmitClusterJob(jobPath,JobOutputFolder,WaitList);
            
            
            % Save the data
            % This is actually redundent because the data is being split
            % and then the subsets saved. But it is very useful for
            % rerunning a job(s).
            ModelInfo.NJobSplit = ActualNJobSplit;
            InDataPath = fullfile(DataFolder,'ModelInfo');
            Str = ['save ' InDataPath ' ModelInfo '];
            eval(Str);
            
        case 'permutation'
            % here the data is used as a whole and only multiple results
            % files are created for each of the permutations
            
            % Save the data
            % This is actually redundent because the data is being split
            % and then the subsets saved.
            InDataPath = fullfile(DataFolder,'ModelInfo');
            Str = ['save ' InDataPath ' ModelInfo '];
            eval(Str);
            
            NPermPerJob = ceil(ModelInfo.Nperm/ModelInfo.NJobSplit);
            
            % Create a list of submitted jobs to be used for executing
            % clean up commands after the jobs have finished.
            WaitList = '';
            
            % Submit the point estimate job
            % Create the cluster submission job
            jobPath = fullfile(InJobFolder,sprintf('PointEst_job.sh'));
            fid = fopen(jobPath,'w');
            
            % Create string of the command to be run with MatLab
            Command = sprintf('VoxelWiseProcessPermute(''%s'',''%d'',''%d'');',InDataPath,0,0);
            % Create the cluster submission script
            CreateClusterJobFile(Command,fid)
            % Submit the script to the cluster
            JobName = SubmitClusterJob(jobPath,JobOutputFolder);
            
            
            % Add job to wait list
            WaitList = sprintf('%s,%s',WaitList,JobName);
            
            % Submit all of the permutation jobs
            for i = 1:ModelInfo.NJobSplit
                % Create the cluster submission job
                jobPath = fullfile(InJobFolder,sprintf('job_%04d.sh',i));
                fid = fopen(jobPath,'w');
                % Create string of the command to be run with MatLab
                Command = sprintf('VoxelWiseProcessPermute(''%s'',''%d'',''%d'');',InDataPath,i,NPermPerJob);
                % Create the cluster submission script
                CreateClusterJobFile(Command,fid)
                % Submit the script to the cluster
                JobName = SubmitClusterJob(jobPath,JobOutputFolder);
                % Add job to wait list
                WaitList = sprintf('%s,%s',WaitList,JobName);
            end
            
            % Write out the resultant images
            Command = sprintf('WriteOutResults(''%s'')',OutFolder);
            jobPath = fullfile(InJobFolder,sprintf('WriteOutJob.sh'));
            fid = fopen(jobPath,'w');
            CreateClusterJobFile(Command,fid)
            % Submit the job with the wait list.
            SubmitClusterJob(jobPath,JobOutputFolder,WaitList);
            
            
    end
else
    % This analysis is run on the host computer
    fprintf(1,'Starting analyses ...')
    switch ModelType
        case 'bootstrap'
            % Save the data
            InDataPath = fullfile(DataFolder,'ModelInfo');
            Str = ['save ' InDataPath ' ModelInfo '];
            eval(Str);
            % Process the data
            Parameters = CycleOverVoxelsProcessBootstrap(ModelInfo);
            
            % Save the results
            ResultsPath = fullfile(OutFolder,'Results');
            mkdir(ResultsPath)
            Str = sprintf('save %s %s',fullfile(ResultsPath,sprintf('BootStrap_count%04d_%dSamp',1,ModelInfo.Nboot)),'Parameters');
            eval(Str)
            
        case 'permutation'
            % The permutation analysis requires calculation of the point
            % estimate and then calculation of all of the permutations. The
            % point estimate is a full set of results and the permutations
            % only require a smaller subset to be calculated. Therefore,
            % the permutation test requires the saving of data to file.
            % The permutation test is also used to calculate the multiple
            % comparison corrected results across voxels. Therefore, it
            % does not make sense to run this type of analysis on a single
            % point data set.
            %
            % Save the data
            InDataPath = fullfile(DataFolder,'ModelInfo');
            Str = ['save ' InDataPath ' ModelInfo '];
            eval(Str);
            
            % Perform the point estimate calculation
            VoxelWiseProcessPermute(InDataPath,0,0)
            % Perform the permutation tests
            VoxelWiseProcessPermute(InDataPath,1,ModelInfo.Nperm)
            
    end
    fprintf(1,' Done!\n');
end



