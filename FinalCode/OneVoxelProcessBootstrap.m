function [Results, BootStrap] = OneVoxelProcessBootstrap(Model)
% reset the random number generator. This is EXTREMEMLY important when
% deploying these analyses to a cluster. Without this resetting then each
% node of the cluster CAN choose the exact same random numbers.
%rng('shuffle','multFibonacci');
seed = 100*clock;
rand('state',seed);

% Fit the model
% The indirect paths (the Paths cell) is set to be an array of cells. This
% is rather a pain in the neck for everything else. 
Results = FitProcessModel(Model);
% perform bootstrap
FieldNames = {'beta' 'B' 'Paths'};
if Model.Nboot > 0
    Model.STRAT = [];
    % The bootstrap propcedure returns the bootstrap distributions from the
    % field names stated above. These same effects are then run through
    % the Jack-Knife procedure.
    try 
       % Perform the jack-knife step
        JackKnife = JackKnifeFunction(Model,Results,FieldNames);    
        BootStrap = BootStrapFunction(Model,Model.Nboot,FieldNames);
%        BoLBBcACI = BagOfBootStrapFunction(Model,100,FieldNames,JackKnife);
        % Calculate the BCaci values for each parameter
        Results.BCaCI = CreateBCaCI(Results,BootStrap,JackKnife,Model.Thresholds);
%        Results.BoLBBCaCI = BoLBBcACI;
    catch me
	fprintf(1,'%s\n', me.message);
%        error('error!');
        Results = [];
    end
end


%% TO DO: unflatten the path BCaCI results
