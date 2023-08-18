#!/bin/bash

if [[ "${NEAR_RELEASE}" == "true" ]]; then
    echo "Test with release version of borsh and near-vm-logic"
    sed -n '/^borsh/p' near-sdk/Cargo.toml 
    sed -n '/^near-vm-logic/p' near-sdk/Cargo.toml
    cargo test --all
else
    echo "Test with git version of borsh and near-vm-logic"

    cargo generate-lockfile

    ### this is section for packages, refusing to work with 1.69
    cargo update -p clap@4.4.1 --precise 4.3.24
    cargo update -p clap_lex@0.5.1 --precise 0.5.0
    ### end of 1.69 threshold section

    cp Cargo.toml{,.bak}
    cp Cargo.lock{,.bak}

    sed -i "" "s|###||g" Cargo.toml
    
    set +e
    cargo test --all
    status=$?
    set -e

    mv Cargo.toml{.bak,}
    mv Cargo.lock{.bak,}
    if [ $status -ne 0 ]; then
      exit $status
    fi

    # Only testing it for one configuration to avoid running the same tests twice
    echo "Build wasm32 for all examples"

    ./examples/build_all_docker.sh --check
    echo "Testing all examples"
    ./examples/test_all.sh
    ./examples/size_all.sh
fi
