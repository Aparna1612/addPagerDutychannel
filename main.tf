
terraform {
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 3.22" 
    }
  }
}

provider  "newrelic" {
    account_id = 3826875
    api_key = "NRAK-BY52LCHM4JNZWY59IXOZXW7J73A"
    region = "US"
}


#newrelic_alert_condition
data "newrelic_entity" "app" {
  name = "FoodME"
  type = "APPLICATION"
  domain = "APM"
}

resource "newrelic_alert_policy" "FoodME_alert_policy" {
  name = "Sample alert policy"
}

resource "newrelic_alert_condition" "FoodME_alert_policy" {
  policy_id = newrelic_alert_policy.FoodME_alert_policy.id

  name        = "Sample condition"
  type        = "apm_app_metric"
  entities    = [ data.newrelic_entity.app.application_id ]
  metric      = "apdex"
  #runbook_url = "https://www.example.com"
  condition_scope = "application"

  term {
    duration      = 5
    operator      = "below"
    priority      = "critical"
    threshold     = "0.75"
    time_function = "all"
  }
}

# Alert destination for PagerDuty
variable "pagerduty_api_token"  { sensitive=true }
resource "newrelic_notification_destination" "service_pd_dest" {
 name = "TEST: my sample PD Dest"
  
type = "PAGERDUTY_SERVICE_INTEGRATION"
  property {
   key = "two_way_integration"
    value = "true"
  }
  auth_token {
    prefix = "Bearer"
    token = "y_NbAkKc66ryYTWUXYEu"
  }
}

# Alert workflow notification channel for PagerDuty
resource "newrelic_notification_channel" "service_pd_channel" {
  account_id = 3826875
  name = "pagerduty-alert-channel"
  type = "PAGERDUTY_SERVICE_INTEGRATION"
  destination_id = newrelic_notification_destination.service_pd_dest.id
  product = "IINT"
  property {
    key = "summary"
    value = "{{ annotations.title.[0] }}"
  }
 # property {
  #  key = "service"
   # value = "P0VPDTO"
  #}
  #property {
   # key = "email"
    #value = "aparna@litmus7.com"
  #}
}




# Alert workflow notification channel for PagerDuty
#workflow

resource "newrelic_workflow" "sample_run_workflow" {
  name = "workflow-pagerduty_demo"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "filter-name"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator = "EXACTLY_MATCHES"
      values = [newrelic_alert_policy.FoodME_alert_policy.id ]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.service_pd_channel.id
  }
}
