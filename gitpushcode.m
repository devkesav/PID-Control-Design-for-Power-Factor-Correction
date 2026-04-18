% =====================================================
% Remove all files from GitHub remote except
% gitpushcode.m  — then force push selected files
% =====================================================1


repoFolder = "D:\project\Control System project";
filesToKeepAndPush = ["PFC_PID_Control_2_.slx", "power_calcalution.m"];
alwaysKeep         = "gitpushcode.m";

oldPwd = pwd;

try
    cd(repoFolder);

    if ~isfolder(".git")
        error("Not a Git repository.");
    end

    %% ── STEP 1: Fetch latest remote so git knows what exists ────
    fprintf("Fetching remote...\n");
    [~, fetchOut] = system('git fetch origin');
    fprintf("%s\n", fetchOut);

    %% ── STEP 2: List every file tracked on remote main ──────────
    [~, remoteFiles] = system('git ls-tree -r --name-only origin/main');
    remoteList = strtrim(splitlines(string(remoteFiles)));
    remoteList = remoteList(strlength(remoteList) > 0);   % drop empty lines

    fprintf("Files currently on remote:\n");
    fprintf("  %s\n", remoteList);

    %% ── STEP 3: git rm --cached every remote file we don't want ─
    for f = remoteList.'
        fname = f;

        % Keep gitpushcode.m
        if fname == alwaysKeep
            continue
        end

        % Keep the files we are about to push
        if any(fname == filesToKeepAndPush)
            continue
        end

        % Remove from git index (not from disk — disk was already cleaned)
        [rmS, rmO] = system(sprintf('git rm --cached --ignore-unmatch "%s"', fname));
        if rmS == 0
            fprintf("Removed from index: %s\n", fname);
        else
            fprintf("Could not remove: %s  — %s\n", fname, rmO);
        end
    end

    %% ── STEP 4: Stage the files we want on remote ───────────────
    for f = filesToKeepAndPush
        if isfile(f)
            system(sprintf('git add "%s"', f));
            fprintf("Staged: %s\n", f);
        else
            warning("File not found locally, skipping: %s", f);
        end
    end

    % Always stage gitpushcode.m
    if isfile(alwaysKeep)
        system(sprintf('git add "%s"', alwaysKeep));
        fprintf("Staged: %s\n", alwaysKeep);
    end

    %% ── STEP 5: Check if anything needs committing ───────────────
    [~, diffOut] = system('git diff --cached --name-only');
    if strlength(strtrim(string(diffOut))) == 0
        fprintf("Nothing new to commit.\n");
    else
        %% ── STEP 6: Commit ───────────────────────────────────────
        commitMsg = "force clean: keep only PFC files and gitpushcode";
        [cS, cO] = system(sprintf('git commit -m "%s"', commitMsg));
        if cS ~= 0
            error("Commit failed:\n%s", cO);
        end
        fprintf("Commit successful:\n%s\n", cO);
    end

    %% ── STEP 7: Force push — overwrites remote completely ────────
    fprintf("Force pushing to origin/main...\n");
    [pS, pO] = system('git push origin main --force');
    if pS ~= 0
        fprintf("Force push failed:\n%s\n", pO);
    else
        fprintf("Force push successful:\n%s\n", pO);
    end

catch ME
    fprintf("\nERROR: %s\n", ME.message);
end

cd(oldPwd);