% ----------------------------------------------------------------------%
% fMRI-Preprocessing Bambi Langzeit: fMRI Odd-one-out task Raphaela
% Schöpfer
%-----------------------------------------------------------------------%

clc
clear all

% Define the list of subjects 
subjects = [384]; % List of subjects

% Loop through subjects
for subject = subjects
    % Convert the subject ID to a zero-padded string 
    subjectStr = num2str(subject, '%02d');
  
    % Specify base paths for raw and source data 
    %rawBasePath = ['/home/sabine/Dokumente/Raphaela/Data/raw_data/sub-' subjectStr '/'];
    %sourceBasePath = ['/home/sabine/Dokumente/Raphaela/Data/source_data/sub-' subjectStr '/'];


    rawBasePath = ['/media/T7Shield/Raphaela/Data/raw_data/sub-' subjectStr '/'];
    sourceBasePath = ['/media/T7Shield/Raphaela/Data/source_data/sub-' subjectStr '/'];

    % Define sessions (session_A and session_B)
    sessions = {'B'};
    
    % Loop through sessions
    for sessionIdx = 1:numel(sessions)
        % Get the current session
        session = sessions{sessionIdx};

        try
        
        % Construct folder paths for raw and source data for the current session
        rawFuncFolder = [rawBasePath 'session_' session '/func'];
        rawAnatFolder = [rawBasePath 'session_' session '/anat'];

        sourceFuncFolder = [sourceBasePath 'session_' session '/func'];
        sourceAnatFolder = [sourceBasePath 'session_' session '/anat'];
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        %--------------------------------------------------------------------------
        % Preprocessing Steps
        %--------------------------------------------------------------------------

        %--------------------------------------------------------------------------
        % Step 1: DICOM Import for Functional Data
        %--------------------------------------------------------------------------
        
        matlabbatch{1}.spm.util.import.dicom.data = cellstr(spm_select('FPList', rawFuncFolder, '.'));
        matlabbatch{1}.spm.util.import.dicom.root = 'flat';
        matlabbatch{1}.spm.util.import.dicom.outdir = {sourceFuncFolder};
        matlabbatch{1}.spm.util.import.dicom.protfilter = '.*';
        matlabbatch{1}.spm.util.import.dicom.convopts.format = 'nii';
        matlabbatch{1}.spm.util.import.dicom.convopts.meta = 0;
        matlabbatch{1}.spm.util.import.dicom.convopts.icedims = 0;
        
        %--------------------------------------------------------------------------
        % Step 2: DICOM Import for Anatomical Data
        %--------------------------------------------------------------------------
        matlabbatch{2}.spm.util.import.dicom.data = cellstr(spm_select('FPList', rawAnatFolder, '.'));
        matlabbatch{2}.spm.util.import.dicom.root = 'flat';
        matlabbatch{2}.spm.util.import.dicom.outdir = {sourceAnatFolder};
        matlabbatch{2}.spm.util.import.dicom.protfilter = '.*';
        matlabbatch{2}.spm.util.import.dicom.convopts.format = 'nii';
        matlabbatch{2}.spm.util.import.dicom.convopts.meta = 0;
        matlabbatch{2}.spm.util.import.dicom.convopts.icedims = 0;


        %--------------------------------------------------------------------------
        % Step 3: Construct filenames
        %--------------------------------------------------------------------------

        % Construct the filenames for functional data
        file1 = fullfile(sourceFuncFolder, ['sub-' subjectStr '_session-' session 'Intu']);
        file2 = fullfile(sourceFuncFolder, ['sub-' subjectStr '_session-' session 'Intu']);

        % Specify the files in batch
        matlabbatch{3}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'Bambi';
        matlabbatch{3}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {
        {file1}
        {file2}
        };

        %--------------------------------------------------------------------------
        % Step 4: Slice timing
        %--------------------------------------------------------------------------
            

        % Modify the slice timing step in the matlabbatch
        matlabbatch{4}.spm.temporal.st.scans{1} = cfg_dep('DICOM Import: Converted Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
        matlabbatch{4}.spm.temporal.st.nslices = 54;
        matlabbatch{4}.spm.temporal.st.tr = 2;
        matlabbatch{4}.spm.temporal.st.ta = 1.963;
        matlabbatch{4}.spm.temporal.st.so = [1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 35 37 39 41 43 45 47 49 51 53 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 5 52 54];
        matlabbatch{4}.spm.temporal.st.refslice = 1;
        matlabbatch{4}.spm.temporal.st.prefix = 'a';
              

        %--------------------------------------------------------------------------
        % Step 5: Realignment - Estimate & Reslice
        %--------------------------------------------------------------------------

        matlabbatch{5}.spm.spatial.realign.estwrite.data{1}(1) = cfg_dep('Slice Timing: Slice Timing Corr. Images (Sess 1)', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
        matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
        matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.sep = 4;
        matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
        matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.rtm = 0;
        matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.interp = 2;
        matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
        matlabbatch{5}.spm.spatial.realign.estwrite.eoptions.weight = '';
        matlabbatch{5}.spm.spatial.realign.estwrite.roptions.which = [2 1];
        matlabbatch{5}.spm.spatial.realign.estwrite.roptions.interp = 4;
        matlabbatch{5}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{5}.spm.spatial.realign.estwrite.roptions.mask = 1;
        matlabbatch{5}.spm.spatial.realign.estwrite.roptions.prefix = 'r';

        %--------------------------------------------------------------------------
        % Step 6: Coregistration - Estimate 
        %--------------------------------------------------------------------------

        matlabbatch{6}.spm.spatial.coreg.estwrite.ref(1) = cfg_dep('Realign: Estimate & Reslice: Mean Image', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','rmean'));
        matlabbatch{6}.spm.spatial.coreg.estwrite.source(1) = cfg_dep('DICOM Import: Converted Images', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
        matlabbatch{6}.spm.spatial.coreg.estwrite.other = {''};
        matlabbatch{6}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
        matlabbatch{6}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
        matlabbatch{6}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
        matlabbatch{6}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
        matlabbatch{6}.spm.spatial.coreg.estwrite.roptions.interp = 4;
        matlabbatch{6}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{6}.spm.spatial.coreg.estwrite.roptions.mask = 0;
        matlabbatch{6}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';

        %--------------------------------------------------------------------------
        % Step 7: Segmentation
        %--------------------------------------------------------------------------
        
        matlabbatch{7}.spm.spatial.preproc.channel.vols(1) = cfg_dep('Coregister: Estimate: Coregistered Images', substruct('.','val', '{}',{6}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
        matlabbatch{7}.spm.spatial.preproc.channel.biasreg = 0.001;
        matlabbatch{7}.spm.spatial.preproc.channel.biasfwhm = 60;
        matlabbatch{7}.spm.spatial.preproc.channel.write = [0 1];
        matlabbatch{7}.spm.spatial.preproc.tissue(1).tpm = {'/home/sabine/Dokumente/Raphaela/Matlab/spm12/tpm/TPM.nii,1'};
        matlabbatch{7}.spm.spatial.preproc.tissue(1).ngaus = 1;
        matlabbatch{7}.spm.spatial.preproc.tissue(1).native = [1 0];
        matlabbatch{7}.spm.spatial.preproc.tissue(1).warped = [0 0];
        matlabbatch{7}.spm.spatial.preproc.tissue(2).tpm = {'/home/sabine/Dokumente/Raphaela/Matlab/spm12/tpm/TPM.nii,2'};
        matlabbatch{7}.spm.spatial.preproc.tissue(2).ngaus = 1;
        matlabbatch{7}.spm.spatial.preproc.tissue(2).native = [1 0];
        matlabbatch{7}.spm.spatial.preproc.tissue(2).warped = [0 0];
        matlabbatch{7}.spm.spatial.preproc.tissue(3).tpm = {'/home/sabine/Dokumente/Raphaela/Matlab/spm12/tpm/TPM.nii,3'};
        matlabbatch{7}.spm.spatial.preproc.tissue(3).ngaus = 2;
        matlabbatch{7}.spm.spatial.preproc.tissue(3).native = [1 0];
        matlabbatch{7}.spm.spatial.preproc.tissue(3).warped = [0 0];
        matlabbatch{7}.spm.spatial.preproc.tissue(4).tpm = {'/home/sabine/Dokumente/Raphaela/Matlab/spm12/tpm/TPM.nii,4'};
        matlabbatch{7}.spm.spatial.preproc.tissue(4).ngaus = 3;
        matlabbatch{7}.spm.spatial.preproc.tissue(4).native = [1 0];
        matlabbatch{7}.spm.spatial.preproc.tissue(4).warped = [0 0];
        matlabbatch{7}.spm.spatial.preproc.tissue(5).tpm = {'/home/sabine/Dokumente/Raphaela/Matlab/spm12/tpm/TPM.nii,5'};
        matlabbatch{7}.spm.spatial.preproc.tissue(5).ngaus = 4;
        matlabbatch{7}.spm.spatial.preproc.tissue(5).native = [1 0];
        matlabbatch{7}.spm.spatial.preproc.tissue(5).warped = [0 0];
        matlabbatch{7}.spm.spatial.preproc.tissue(6).tpm = {'/home/sabine/Dokumente/Raphaela/Matlab/spm12/tpm/TPM.nii,6'};
        matlabbatch{7}.spm.spatial.preproc.tissue(6).ngaus = 2;
        matlabbatch{7}.spm.spatial.preproc.tissue(6).native = [0 0];
        matlabbatch{7}.spm.spatial.preproc.tissue(6).warped = [0 0];
        matlabbatch{7}.spm.spatial.preproc.warp.mrf = 1;
        matlabbatch{7}.spm.spatial.preproc.warp.cleanup = 1;
        matlabbatch{7}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{7}.spm.spatial.preproc.warp.affreg = 'mni';
        matlabbatch{7}.spm.spatial.preproc.warp.fwhm = 0;
        matlabbatch{7}.spm.spatial.preproc.warp.samp = 3;
        matlabbatch{7}.spm.spatial.preproc.warp.write = [0 1];
        matlabbatch{7}.spm.spatial.preproc.warp.vox = NaN;
        matlabbatch{7}.spm.spatial.preproc.warp.bb = [NaN NaN NaN
                                                      NaN NaN NaN];


        %--------------------------------------------------------------------------
        % Step 8: Normalization
        %--------------------------------------------------------------------------

        matlabbatch{8}.spm.spatial.normalise.write.subj(1).def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{7}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
        matlabbatch{8}.spm.spatial.normalise.write.subj(1).resample(1) = cfg_dep('Realign: Estimate & Reslice: Realigned Images (Sess 1)', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{1}, '.','cfiles'));
        matlabbatch{8}.spm.spatial.normalise.write.subj(2).def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{7}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
        matlabbatch{8}.spm.spatial.normalise.write.subj(2).resample(1) = cfg_dep('Coregister: Estimate: Coregistered Images', substruct('.','val', '{}',{6}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
        matlabbatch{8}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                                  78 76 85];
        matlabbatch{8}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
        matlabbatch{8}.spm.spatial.normalise.write.woptions.interp = 4;
        matlabbatch{8}.spm.spatial.normalise.write.woptions.prefix = 'w';

           
       
        %--------------------------------------------------------------------------
        % Step 9: Smoothing
        %--------------------------------------------------------------------------

        matlabbatch{9}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{8}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
        matlabbatch{9}.spm.spatial.smooth.fwhm = [5 5 5];
        matlabbatch{9}.spm.spatial.smooth.dtype = 0;
        matlabbatch{9}.spm.spatial.smooth.im = 0;
        matlabbatch{9}.spm.spatial.smooth.prefix = 's';
      
        spm_jobman('run', matlabbatch); 

        %--------------------------------------------------------------------------
        % End of Preprocessing Steps
        %--------------------------------------------------------------------------

    catch ME
        disp(['Error occurred for Subject ', num2str(subject), ' Session ', session, ': ', ME.message]);
        continue; % move to the next session
    end
  end
end

