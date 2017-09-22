elifePipeline {
    def commit
    stage 'Checkout', {
        checkout scm
        commit = elifeGitRevision()
    }

    elifePullRequestOnly { prNumber ->
        stage 'Applying to a stack', {
            def instance = "pr-${prNumber}"
            def stackname = "medium--${instance}"
            try {
                sh "/srv/builder/bldr destroy:${stackname}"
                sh "/srv/builder/bldr masterless.launch:medium,${instance}"
                sh "/srv/builder/bldr masterless.set_versions:${stackname},medium-formula@${commit}"
                sh "/srv/builder/bldr update:${stackname}"
                // TODO: run smoke tests
            } finally {
                sh "/srv/buulder/bldr destroy:${stackname}"
            }
        }
    }
}
