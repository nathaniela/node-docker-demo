# node-deker-demo

A generic Gitflow multibranch Jenkins pipeline
TODO: add enforcement for git naming

Docker Build when:
1. push to develop (gitTag:'dev-[git commit]')
2. push to release/v[version] (gitTag:'rc-[version]-[git commit]')
3. when accepting a pull request to master from release (gitTag:'v[version]')
   - The build process with tag the image that was created during the source commit

## releases

### v1.0.0
- develop branch pipeline flow.

### v1.0.1
- release branch pipeline flow.
- Git webhook integration

### v1.0.2
- show Yakir the pipeline
