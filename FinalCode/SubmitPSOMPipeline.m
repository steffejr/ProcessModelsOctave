function SubmitPSOMPipeline(pipeline,ModelInfo)
% Set up options
opt = {}
opt.path_logs = fullfile(ModelInfo.BaseDir,'logs');
opt.mode = 'qsub';
opt.mode_pipeline_manager = 'session';
opt.max_queued = ModelInfo.NJobSplit;
psom_run_pipeline(pipeline,opt)
