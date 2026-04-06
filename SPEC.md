# SPEC.md

This is the spec file that will generate most of the files in this repository. Launch it with any agent (in my case Antigravity) with "Follow the spec laid out in @SPEC.md" and watch it generate. This should only be used once to generate the initial files and then the repository should be self sufficient. It's stored here as a reference for how the repository was generated.

# Specification

opencode container is a way to expose opencode via a web interface with openchamber (https://github.com/openchamber/openchamber).

The goal of this repository is to have:
1. A dockerfile that builds the image. That contains the cli tools for opencode, and other tools that I use frequently from these agent cli tools. The dockerfile should contain the OCI compliant metadata.
1. A helm chart that will deploy the image to a k8s cluster. It should be configured to use a persistent volume for the workspace home directory which will contain the agent config files, and should be configured to use a service account that has read only access to the k8s cluster for kubectl commands, it should not have access to secrets. It should also be configured to use a either an ingress or gateway to expose the service, configured via values. It will be pushed to ghcr as an OCI package.
1. Local and CI tests for the helm chart, using helm test and helm lint.
1. Local and CI tests for the dockerfile. These tests should verify that the image builds correctly and that the tools are installed correctly.
1. The tests do not have to be extensive, deployment will take place in a k3s cluster that I run that that will be the ultimate usability test. Here we try and keep the pipeline runs fast and efficient, but still with some coverage.
1. A readme file explaining what the repository is, how to use it, and how to deploy it to a k8s cluster with an example helm values file.
1. A .gitignore file that will ignore the workspace home directory and .env file if requried. Any files that do not need to be checked in.
1. A LICENCE file that will allow the code to be used in any way that I see fit and is compatible with the btriapitsyn/openchamber license.
1. A CODEOWNERS file that will assign me as the code owner.
1. _My_ Preference is python, but the upstream repo is node. If we need to write something in a language more complicated than shell scripts then me the correct decision here that make sense. 

The repository will be configured with:
1. A github action that will create a release when a new tag is pushed, and will update the image tag in the helm chart to match the release tag.
1. Github actions almost exactly the same as this example https://github.com/ryanbeales/immich-album-export/blob/main/.github/workflows/build-push.yaml that will build and push the image to github container registry. The resulting image should be tagged with the release tag
1. The commits will follow conventaionalcommits https://www.conventionalcommits.org/en/v1.0.0/
1. The tags will follow semantic versioning https://semver.org/
1. Tags will be auto generated based on the commits when PRs are merged to main
1. A github action will run on PRs to test the branch, and auto merge will be enabled for PRs that pass the tests
1. A renovatebot config that will keep dependancies up to date https://github.com/ryanbeales/immich-album-export/blob/main/.github/renovate.json5
1. The repository will be public.
1. We want to rebuild the image nightly to capture new releases of the upstream repo and the tools we use in the dockerfile as they are released. So a nightly build is probably the best bet with newly tagged releases after trigging a build.

If the repository does not exist, it needs to be created and configured as per the above instructions. The `gh` cli tool is availabled and logged in for the ryanbeales user. The repository should be created in the ryanbeales user account.

Things not to do:
1. Do not use alpine as a base for the dockerfile. We disagree with musl for _reasons_ (it works, but it doesn't have to work here).

# Postscript

This requried some tweaking after creationg since it wasn't a blank slate. I'd used the existing claudecodeui-container repo as a base. But it mostly worked with this in place, perhaps it should be changed to a skill/workflow in future to make it easier to generate the pipelines for new repos.