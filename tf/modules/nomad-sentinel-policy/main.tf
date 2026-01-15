resource "nomad_sentinel_policy" "restrict_artifact_sources" {
  name             = "restrict-artifact-sources"
  description      = "Only allow artifacts from approved sources"
  enforcement_level = "hard-mandatory"
  scope            = "submit-job"

  policy = <<-EOT
    # restrict-artifact-sources.sentinel
    # Ensures all artifacts are sourced from approved locations

    import "strings"

    # Approved artifact source prefixes
    allowed_prefixes = ${jsonencode(var.allowed_artifact_prefixes)}

    # Check if artifact source starts with an allowed prefix
    is_approved_source = func(source) {
      for allowed_prefixes as prefix {
        if strings.has_prefix(source, prefix) {
          return true
        }
      }
      return false
    }

    # Check if task has only approved artifacts
    has_approved_artifacts = func(task) {
      # If no artifacts, that's fine
      if task.artifacts is not defined or task.artifacts is null or length(task.artifacts) == 0 {
        return true
      }

      for task.artifacts as artifact {
        if not is_approved_source(artifact.source) {
          print("Task", task.name, "has unapproved artifact source:", artifact.source)
          return false
        }
      }

      return true
    }

    # Main rule: all tasks must have approved artifacts
    main = rule {
      all job.task_groups as tg {
        all tg.tasks as task {
          has_approved_artifacts(task)
        }
      }
    }
  EOT
}
