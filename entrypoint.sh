#!/bin/sh -l
set -e

file_name=$1
tag_version=$2
echo "\nInput file name: $file_name : $tag_version"

echo "Git Head Ref: ${GITHUB_HEAD_REF}"
echo "Git Base Ref: ${GITHUB_BASE_REF}"
echo "Git Event Name: ${GITHUB_EVENT_NAME}"

echo "\nStarting Git Operations"
git config --global user.email "Bump-N-Tag@github-action.com"
git config --global user.name "Bump-N-Tag App"

github_ref=""

if test "${GITHUB_EVENT_NAME}" = "push"
then
    github_ref=${GITHUB_REF}
else
    github_ref=${GITHUB_HEAD_REF}
    git checkout $github_ref
fi


echo "Git Checkout"

if test -f $file_name; then
    content=$(cat $file_name)
else
    content=$(echo "-- File doesn't exist --")
fi

extract_string=$(echo $content|busybox grep -P '(?<=CURRENT_VERSION ")(.*)(?=")' -o)

if [[ "$extract_string" == "" ]]; then 
    echo "\nInvalid version string"
    exit 0
else
    echo "\nValid version string found"
fi

major=$(echo $extract_string | cut -d'.' -f1) 
minor=$(echo $extract_string | cut -d'.' -f2)
patch=$(echo $extract_string | cut -d'.' -f3)
build=$(echo $extract_string | cut -d'.' -f4)


oldver=$(echo $major.$minor.$patch.$build)
build=$(expr $build + 1)
newver=$(echo $major.$minor.$patch.$build)

echo "\nOld Ver: $oldver"
echo "\nUpdated version: $newver" 

newcontent=$(echo ${content/$oldver/$newver})
echo $newcontent > $file_name

git add -A 
git commit -m "Incremented to ${newver}"  -m "[skip ci]"
([ -n "$tag_version" ] && [ "$tag_version" = "true" ]) && (git tag -a "${newver}" -m "[skip ci]") || echo "No tag created"

git show-ref
echo "Git Push"

git push --follow-tags "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" HEAD:$github_ref


echo "\nEnd of Action\n\n"
exit 0
