function WriteVertexFiles(Data,File,Vertices,hemi)
% File the data in with blanks as needed
load('/home/jason/Documents/Papers/MediationMethods/Results/VertexAnalyses/VertexIndices.mat');
switch hemi
    case 'lh'
        FullData = zeros(length(LHVertex),1);
        for i = 1:length(Data)
            FullData(Vertices(1,i)+1,1) = Data(i);
        end
        fid = fopen(File,'w');
        if fid < 3
            error('Cannot open file!');
        else
            for i = 1:length(FullData)
                fprintf(fid,'%03d %0.5f %0.5f %0.5f %0.5f\n',LHVertex(1,i),LHVertex(2,i),LHVertex(3,i),LHVertex(4,i),FullData(i,1));
            end
            fclose(fid);
        end
    case 'rh'
        FullData = zeros(length(RHVertex),1);
        for i = 1:length(Data)
            FullData(Vertices(1,i)+1,1) = Data(i);
        end
        fid = fopen(File,'w');
        if fid < 3
            error('Cannot open file!');
        else
            for i = 1:length(FullData)
                fprintf(fid,'%03d %0.5f %0.5f %0.5f %0.5f\n',RHVertex(1,i),RHVertex(2,i),RHVertex(3,i),RHVertex(4,i),FullData(i,1));
            end
            fclose(fid);
        end
        
end


