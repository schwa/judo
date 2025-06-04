generate-random-repo:
    #!/usr/bin/env fish

    set repo_path /tmp/fake-repo
    rm -rf $repo_path
    mkdir -p $repo_path
    cd $repo_path
    git init
    jj git init --colocate
    for i in (seq 1 5)
        echo "File $i Content" > file_$i.txt
        jj commit -m "Fake Commit A_$i"
    end

    jj new zz

    for i in (seq 1 5)
        echo "File $i Content" > file_$i.txt
        jj commit -m "Fake Commit B_$i"
    end

    jj new 'description("A_5")' 'description("B_5")'
    jj describe -m "Merged A_5 and B_5"

    jj log
