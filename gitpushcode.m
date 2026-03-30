% ==========================================
% Commit & Push selected files to Git repo
% Removes all other files except gitpushcode.m
% ==========================================

repoFolder = "D:\project\Control System project";
filesToAdd = ["PFC_PID_Control_2_.slx", "power_calcalution.m"];
keepFile   = "gitpushcode.m";

oldPwd = pwd;

try
    cd(repoFolder);

    %% ── Guard: must be a git repo ────────────────────────
    if ~isfolder(".git")
        error("Not a Git repository. Run: git init");
    end

    %% ── Guard: files to commit must exist ────────────────
    for f = filesToAdd
        if ~isfile(f)
            error("File not found in repo folder: %s", f);
        end
    end

    %% ── STEP 1: Remove every file except keepFile ────────
    allItems = dir(fullfile(repoFolder, "**", "*"));
    allItems = allItems(~[allItems.isdir]);   % files only

    for k = 1 : numel(allItems)
        fullP = string(fullfile(allItems(k).folder, allItems(k).name));

        % Skip anything inside .git/
        if contains(fullP, filesep + ".git" + filesep) || ...
           endsWith(fullP, filesep + ".git")
            continue
        end

        % Skip the file we always keep
        [~, nm, ex] = fileparts(fullP);
        thisName = nm + ex;
        if thisName == keepFile
            continue
        end

        % Skip the files we are about to commit
        if any(thisName == filesToAdd)
            continue
        end

        % Stage deletion in git, then delete from disk
        system(sprintf('git rm --cached --ignore-unmatch "%s"', fullP));
        try
            delete(fullP);
            fprintf("Removed: %s\n", fullP);
        catch
            warning("Could not delete: %s", fullP);
        end
    end

    %% ── STEP 2: Stage only the target files ──────────────
    for f = filesToAdd
        [~, out] = system(sprintf('git add "%s"', f));
        fprintf("Staged: %s\n", f);
    end

    % Also stage keepFile in case it was modified
    if isfile(keepFile)
        system(sprintf('git add "%s"', keepFile));
    end

    %% ── STEP 3: Check if anything is actually staged ─────
    [~, stagedOut] = system('git diff --cached --name-only');
    nothingStaged  = strlength(strtrim(string(stagedOut))) == 0;

    if nothingStaged
        fprintf("Nothing staged — no commit needed.\n");
    else
        %% ── STEP 4: Get commit message ───────────────────
        if usejava("desktop")
            answer = inputdlg("Enter commit message:", ...
                              "Commit Message", 1, {"update PFC files"});
            if isempty(answer)
                fprintf("Commit cancelled.\n");
                cd(oldPwd);
                return;
            end
            commitMsg = answer{1};
        else
            commitMsg = input("Enter commit message: ", "s");
        end

        %% ── STEP 5: Commit ───────────────────────────────
        [commitStatus, commitOut] = system(sprintf('git commit -m "%s"', commitMsg));
        if commitStatus ~= 0
            error("Commit failed:\n%s", commitOut);
        end
        fprintf("Commit successful:\n%s\n", commitOut);
    end

    %% ── STEP 6: Push ─────────────────────────────────────
    [pushStatus, pushOut] = system('git push');
    if pushStatus ~= 0
        fprintf("Push failed:\n%s\n", pushOut);
    else
        fprintf("Push successful:\n%s\n", pushOut);
    end

catch ME
    fprintf("\nERROR: %s\n", ME.message);
end

cd(oldPwd);