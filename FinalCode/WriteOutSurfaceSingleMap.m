function WriteOutSurfaceSingleMap(Tag,Parameters,ModelInfo,FDRFlag)
if nargin == 3
    FDRFlag = 0;
end



% If a subfield is passed.
if ~isempty(findstr(Tag,'.'))
    Field = Tag(1:findstr(Tag,'.')-1);
    temp1 = getfield(Parameters{1},Field);
    temp = zeros([size(getfield(temp1,Tag(findstr(Tag,'.')+1:end))) ModelInfo.Nvoxels]);
else
    temp = zeros([size(getfield(Parameters{1},Tag)) ModelInfo.Nvoxels]);
end
% If a subfield is passed.
for i = 1:ModelInfo.Nvoxels
    if ~isempty(Parameters{i})
        if ~isempty(findstr(Tag,'.'))
            Field = Tag(1:findstr(Tag,'.')-1);
            temp1 = getfield(Parameters{i},Field);
            temp(:,:,i) = getfield(temp1,Tag(findstr(Tag,'.')+1:end));
        else
            temp(:,:,i) = getfield(Parameters{i},Tag);
        end
    end
end

if strcmp(Tag,'BCaCI.PathsP') && FDRFlag
    Tag = sprintf('%s_%s',Tag,'FDR');
    % Only use the first threshold
    kk = 1;
    alpha = ModelInfo.Thresholds(kk);
    % Cycle over each parameter
    [m n p] = size(temp);
    for i = 1:m
        for j = 1:n
            CurrentTemp = squeeze(temp(i,j,:));
            I = sort(CurrentTemp);
            [FDRp, FDRpN] = FDR(I,alpha);
            if isempty(FDRp)
                FDRp = 1/ModelInfo.Nvoxels*alpha;
            end
            CurrentTemp(find(CurrentTemp > FDRp)) = 0;
            temp(i,j,:) =  CurrentTemp;
        end
    end
end
for j = 1:size(temp,2)
    for i = 1:size(temp,1)

        FileName = sprintf('Path%d_level%03d_%s',i,j,Tag);
        % Working with surface maps
        Ilh = zeros(length(ModelInfo.lhVertices),1);
        Irh = zeros(length(ModelInfo.rhVertices),1);
        LHindices = 1:length(ModelInfo.lhVertices);
        RHindices = 1:length(ModelInfo.rhVertices);
        Ilh(LHindices) = squeeze(temp(i,j,LHindices));
        Irh(RHindices) = squeeze(temp(i,j,length(LHindices)+RHindices));
        % Write data to files

        WriteVertexFiles(Ilh,fullfile(ModelInfo.ResultsPath,[FileName '.lh.asc']),ModelInfo.lhVertices,'lh')
        WriteVertexFiles(Irh,fullfile(ModelInfo.ResultsPath,[FileName '.rh.asc']),ModelInfo.rhVertices,'rh')

    end
end