#!/usr/bin/env bash


if [[ -z "${JENKINS_HOST}" ]] || [[ -z "${USER_NAME}" ]] || [[ -z "${API_TOKEN}" ]] || [[ -z "${GIT_REPO}" ]] || [[ -z "${GIT_CREDENTIALS}" ]]; then
    echo -e "Pipeline registration script is missing required fields"
    echo -e "Expected environment variables: {JENKINS_HOST} {USER_NAME} {API_TOKEN} {GIT_REPO} {GIT_BRANCH} {CONFIG_FILE}"
    echo -e "  where:"
    echo -e "    JENKINS_HOST - the host name of the Jenkins server"
    echo -e "    USER_NAME - the Jenkins user name"
    echo -e "    API_TOKEN - the Jenkins api token"
    echo -e "    GIT_REPO - the url of the git repo"
    echo -e "    GIT_CREDENTIALS - the name of the secret holding the git credentials"
    echo -e "    GIT_BRANCH - the branch that should be registered for the build. Defaults to 'master'"
    echo -e "    CONFIG_FILE - the file containing the pipeline config. Defaults to 'config-template.xml'"
    echo -e ""
    exit 1
fi

JOB_NAME=$(echo "${GIT_REPO}" | sed -e "s~.*/\(.*\)~\1~" | sed "s/.git//")
if [[ "${GIT_BRANCH}" != "master" ]]; then
    JOB_NAME="${JOB_NAME}_${GIT_BRANCH}"
fi

echo "Registering ${JOB_NAME} for ${GIT_REPO} with ${JENKINS_HOST} as ${USER_NAME}"

CRUMB=$(curl -s "${JENKINS_HOST}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)" -u "${USER_NAME}:${API_TOKEN}")
cat /home/devops/etc/jenkins-config-template.xml | \
    sed "s~{{GIT_REPO}}~${GIT_REPO}~g" | \
    sed "s~{{GIT_CREDENTIALS}}~${GIT_CREDENTIALS}~g" | \
    sed "s~{{GIT_BRANCH}}~${GIT_BRANCH}~g" | \
    curl -s -X POST "${JENKINS_HOST}/createItem?name=${JOB_NAME}" -u "${USER_NAME}:${API_TOKEN}" -d @- -H "${CRUMB}" -H "Content-Type:text/xml"
