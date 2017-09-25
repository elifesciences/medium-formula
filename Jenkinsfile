elifePipeline {
    def commit
    stage 'Checkout', {
        checkout scm
        commit = elifeGitRevision()
    }

    elifePullRequestOnly { prNumber ->
        def instance = "pr-${prNumber}"
        def stackname = "medium--${instance}"
        try {
            stage 'Basic stack', {
                sh "/srv/builder/bldr ensure_destroyed:${stackname}"
                sh "/srv/builder/bldr masterless.launch:medium,${instance}"
            }

            stage 'Applying change', {
                sh "/srv/builder/bldr masterless.set_versions:${stackname},medium-formula@${commit}"
                sh "/srv/builder/bldr update:${stackname}"
                // TODO: run smoke tests
            }
        } finally {
            stage 'Cleanup', {
                sh "/srv/builder/bldr ensure_destroyed:${stackname}"
            }
        }
    }
}
