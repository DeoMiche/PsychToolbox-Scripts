%%
% This script implements the two flash fusion task (see Deodato & Melcher,
% 2023). The two-flash fusion task is a short computer procedure that aims 
% at quantifying an individual’s visual temporal acuity: the shortest time 
% interval between two stimuli that can be reliably perceived.

% author: Michele Deodato
% email: deodato.mic@gmail.com
%%
clearvars
Screen('Preference', 'SkipSyncTests', 1);

% PARTICIPANT DATA
name1='Participant Data';
prompt1={'Subject Number', ...
    'Subject ID', ...
    'Sex (f/m)', ...
    'Age'};
numlines1=1;
defaultanswer1={ '0', 'pilot', 'M', '0', '1'};
answer1=inputdlg(prompt1,name1,numlines1,defaultanswer1);
DEMO.num = str2double(answer1{1});
DEMO.ID  = answer1{2};
DEMO.sex = answer1{3};
DEMO.age = str2double(answer1{4});
DEMO.date = datetime;

try 
    % KEYBOARD SETUP
    KbName('UnifyKeyNames');
    responseKeys = {'z','m'};
    KbCheckList = [KbName('space'),KbName('ESCAPE')];
    for i = 1:length(responseKeys)
        KbCheckList = [KbName(responseKeys{i}),KbCheckList];
    end
    RestrictKeysForKbCheck(KbCheckList);
    ListenChar(-1)
    HideCursor();

    % SCREEN SETUP
    s = max(Screen('Screens'));
    [w, rect] = Screen('Openwindow',s,[255 255 255]/2);
    Priority(MaxPriority(w));
    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);    
    SCREEN.fps=Screen('FrameRate',w);
    SCREEN.size = rect;  
    [wx, wy] = RectCenter(rect);
    Screen('Flip', w);
    
    % STIMULI SETUP
    rng('shuffle')
    expTable = [];
    isi = [0,1,2,3,4,5];
    side = [-1, 1];
    i_trial = 1;
    nRep = 12;
    
    for i_rep = 1:nRep
        for i_side = 1:length(side)
            for i_isi = 1:length(isi)
                if i_rep == 1
                    trainTable(i_trial,:) = [isi(i_isi), side(i_side), 1, nan, nan, nan, nan];
                end
                expTable(i_trial,:) = [isi(i_isi), side(i_side), 0, nan, nan, nan, nan];
                i_trial = i_trial+1;
            end
        end
    end
    
    expTable = expTable(randperm(size(expTable,1)), :);
    trainTable = trainTable(randperm(size(trainTable,1)), :);
    expLabels = {'isi', 'side', 'training', 'response', 'rt', 'flash1', 'flash2'};
    expTable = array2table([trainTable; expTable], 'VariableNames', expLabels);
    
    fixRadius = 7;
    fixRect = CenterRectOnPoint([0, 0, fixRadius*2, fixRadius*2], wx, wy);
    fixColor = [255 255 255];
    fixColor2 = [0 0 0];
    
    flashRadius = 15;
    flashOffset = 200;
    flashColor = [152 152 152];

    % INSTRUCTIONS
    Screen('DrawText', w, 'YOU HAVE TO LOOK AT THE CENTRAL WHITE CIRCLE',  wx-450, wy-50, [0,0,0]);
    Screen('DrawText', w, '1 OR 2 FLASHES WILL APPEAR EITHER ON THE LEFT OR RIGHT SIDE OF THE CIRCLE',  wx-450, wy, [0,0,0]);
    Screen('DrawText', w, 'PRESS "Z" IF YOU SEE 1 FLASH, PRESS "M" IF YOU SEE 2 FLASHES',  wx-450, wy+50, [0,0,0]);
    Screen('Flip', w);
    KbWait([],2)
      
    % EXPERIMENT
    Screen('DrawText', w, 'PRESS SPACE TO START',  wx-150, wy, [0,0,0]);
    Screen('Flip', w);
    KbWait([],2)
    tic
    for i_trial = 1:size(expTable,1)
        % BREAK
        if mod(i_trial,size(expTable,1)/2+1) == 0
            Screen('DrawText', w, 'TAKE A BREAK',  wx-300, wy-100, [0,0,0]);
            Screen('DrawText', w, 'PRESS SPACE TO CONTINUE',  wx-300, wy, [0,0,0]);
            Screen('Flip', w);
            KbWait([],2)
        end

        % ITI
        flashRect = CenterRectOnPoint([0, 0, flashRadius*2, flashRadius*2], wx+(flashOffset*expTable.side(i_trial)), wy);
        Screen('FillOval', w, fixColor, fixRect);
        Screen('Flip', w);
        WaitSecs(1+randperm(500,1)/1000)

        % FIRST FLASH
        Screen('FillOval', w, fixColor, fixRect);
        Screen('FillOval', w, flashColor, flashRect);
        [~, ~, expTable.flash1(i_trial)] = Screen('Flip', w);

        % ISI
        for i_isi = 1:expTable.isi(i_trial)
            Screen('FillOval', w, fixColor, fixRect);
            Screen('Flip', w);
        end

        % SECOND FLASH
        Screen('FillOval', w, fixColor, fixRect);
        Screen('FillOval', w, flashColor, flashRect);
        [~, ~, expTable.flash2(i_trial)] = Screen('Flip', w);

        Screen('FillOval', w, fixColor, fixRect);
        Screen('Flip', w);
        WaitSecs(1)

        % RESPONSE
        Screen('FillOval', w, fixColor2, fixRect);
        Screen('DrawText', w, 'One Flash (z) or Two Flashes (m) ?',  wx-150, wy+200, [0,0,0]);
        [VBLTimestamp, StimulusOnsetTime, FlipTimestamp] = Screen('Flip', w);
        [ResponseTime, keyCode] = KbWait([],2);
        
        if find(keyCode) == KbName('escape')
            ShowCursor()
            ListenChar(0)
            RestrictKeysForKbCheck([]);
            Screen(w,'Close');
            close all
            sca;
        else
            expTable.response(i_trial) = find(keyCode);
            expTable.rt(i_trial) = ResponseTime-FlipTimestamp;
        end
    end
    
    % SAVE BEHAV DATA
    EXP.DEMO = DEMO;
    EXP.SCREEN = SCREEN;
    EXP.data = expTable;
    EXP.duration = toc;
    save([answer1{1} '_FF_' answer1{2} '.mat'], 'EXP')
    
    % finish the experiment
    ShowCursor()
    ListenChar(0)
    RestrictKeysForKbCheck([]);
    Screen(w,'Close');
    close all
    sca;
    
catch
    % finish the experiment  
    ShowCursor()
    ListenChar(0)
    RestrictKeysForKbCheck([]);
    Screen(w,'Close');
    close all
    sca;
    rethrow(lasterror)
end