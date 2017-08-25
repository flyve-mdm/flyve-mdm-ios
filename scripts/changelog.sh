#!/bin/bash
echo ---------------TRAVIS_BRANCH----------------
    echo $TRAVIS_BRANCH
echo -----------------CHANGELOG-------------------
if [[ "$TRAVIS_BRANCH" == "feature/version" && "$TRAVIS_PULL_REQUEST" == "false" ]]; then
    
    echo ------------------CONFIG--------------------
    git config --global user.email $GH_EMAIL
    git config --global user.name "Travis CI"
    git remote remove origin
    git remote add origin https://$GH_USER:$GH_TOKEN@github.com/flyve-mdm/flyve-mdm-ios-agent.git
    echo ------------------RELEASE--------------------
    
    if [[ $TRAVIS_COMMIT_MESSAGE != *"**version**"* && $TRAVIS_COMMIT_MESSAGE != *"**CHANGELOG.md**"* ]]; then
        git checkout $TRAVIS_BRANCH -f
        conventional-github-releaser -t $GH_TOKEN -r 0
        npm run release -- -m "ci(release): generate **CHANGELOG.md** for version %s"
        # Get version number from package
        
        export GIT_TAG=$(jq -r ".version" package.json)
        # git push origin ${GIT_TAG}
        # # Update CFBundleShortVersionString   
        # /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${GIT_TAG}" ${PWD}/${APPNAME}/Info.plist
        # git add ${APPNAME}/Info.plist
        # Rename last commit
        git commit -m "ci(build): increment **version** ${GIT_TAG}"

        git push --follow-tags origin $TRAVIS_BRANCH

        # fastlane release
    fi
fi