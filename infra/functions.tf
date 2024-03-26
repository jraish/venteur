resource "digitalocean_app" "knights_path" {
  spec {
    name   = "knights_path"
    region = "nyc1"
    domain {
        name = "knights_path.venteur.com"
    }

    alert {
        rule = "DEPLOYMENT_FAILED"
    }

    function {
        name             = "process_request"
        source_dir       = "functions/process_request/app.py"
        build_command    = "./build.sh"
        github {
            branch         = "main"
            deploy_on_push = true
            repo           = "jraish/venteur"
        }

        env {
            key            = "db_host"
            value          = self.database.host
        }

        # alert {
        #     value    = 75
        #     operator = "GREATER_THAN"
        #     window   = "TEN_MINUTES"
        #     rule     = "CPU_UTILIZATION"
        # }
    }

    database {
        name       = "result_db"
        engine     = "PG"
        production = false
    }

    database {
        name       = "path_cache"
        engine     = "REDIS"
        production = false
    }

    ingress {
      rule {
        component {
          name = "process_request"
        }
        match {
          path {
            prefix = "/"
          }
        }
      }
  }
}