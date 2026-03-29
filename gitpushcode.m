% ==========================================
% FULL Git Auto Commit + Push (FIXED)
% ==========================================

repoFolder = "D:\project\Control System project";
oldPwd = pwd;

try
    cd(repoFolder);

    % Ensure repo exists
    if ~isfolder(".git")
        error("Not a Git repository. Run: git init");
    end

    % --------------------------------------
    % STEP 1: Add ALL changes (important fix)
    % --------------------------------------
    system('git add .');

    % --------------------------------------
    % STEP 2: Check for changes
    % --------------------------------------
    [statusCheck, cmdout] = system('git status --porcelain');

    if statusCheck ~= 0
        error("Git status failed:\n%s", cmdout);
    end

    if strlength(strtrim(string(cmdout))) == 0
        fprintf("No changes to commit.\n");

        % Still try pushing (since you're ahead)
        system('git push');
        cd(oldPwd);
        return;
    end

    % --------------------------------------
    % STEP 3: Commit message
    % --------------------------------------
    if usejava("desktop")
        answer = inputdlg("Enter commit message:", ...
                          "Commit Message", 1, {"Auto update"});
        if isempty(answer)
            fprintf("Commit cancelled.\n");
            cd(oldPwd);
            return;
        end
        commitMsg = answer{1};
    else
        commitMsg = input("Enter commit message: ", "s");
    end

    % --------------------------------------
    % STEP 4: Commit
    % --------------------------------------
    [commitStatus, commitOut] = system(sprintf('git commit -m "%s"', commitMsg));

    if commitStatus ~= 0
        fprintf("Commit skipped:\n%s\n", commitOut);
    else
        fprintf("Commit success:\n%s\n", commitOut);
    end

    % --------------------------------------
    % STEP 5: Push
    % --------------------------------------
    [pushStatus, pushOut] = system('git push');

    if pushStatus ~= 0
        fprintf("Push failed:\n%s\n", pushOut);
    else
        fprintf("Push success:\n%s\n", pushOut);
    end

catch ME
    fprintf("\nERROR:\n%s\n", ME.message);
end

cd(oldPwd);