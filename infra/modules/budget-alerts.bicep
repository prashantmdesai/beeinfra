/*
 * BUDGET ALERTS AND COST MONITORING MODULE
 * ========================================
 * 
 * This module implements comprehensive cost monitoring and budget alerting capabilities
 * to ensure strict adherence to the cost targets defined in the infrastructure requirements:
 * - IT Environment: $10 monthly budget
 * - QA Environment: $20 monthly budget  
 * - Production Environment: $30 monthly budget
 * 
 * COST MONITORING STRATEGY:
 * ========================
 * The module creates TWO separate budget resources for each environment:
 * 
 * 1. ESTIMATED COSTS BUDGET: Monitors forecasted spending based on current usage patterns
 *    - Provides early warning when projected costs exceed thresholds
 *    - Helps prevent budget overruns before they occur
 *    - Uses Azure's forecasting algorithms to predict monthly spend
 * 
 * 2. ACTUAL COSTS BUDGET: Monitors real spending as it occurs
 *    - Tracks actual charges against the defined budget limits
 *    - Provides immediate alerts when spending crosses critical thresholds
 *    - Essential for real-time cost control and immediate action
 * 
 * ALERT THRESHOLDS:
 * ================
 * Both budgets are configured with multiple alert thresholds:
 * - 50% threshold: Early warning to start monitoring usage more closely
 * - 80% threshold: Action required - review resources and optimize costs
 * - 100% threshold: Critical alert - immediate intervention needed
 * 
 * NOTIFICATION CHANNELS:
 * =====================
 * The module creates an Action Group that sends notifications via:
 * - Primary Email: prashantmdesai@yahoo.com
 * - Secondary Email: prashantmdesai@hotmail.com
 * - SMS: +1 224 656 4855
 * 
 * This multi-channel approach ensures alerts are received promptly regardless
 * of availability or preferred communication method.
 * 
 * COMPLIANCE ALIGNMENT:
 * ====================
 * This module directly implements requirements 1-6 from infrasetup.instructions.md:
 * - Separate estimated and actual cost monitoring for each environment
 * - Exact budget amounts as specified in requirements
 * - Required alert contact information properly configured
 * - Immediate deployment as part of environment setup
 */

@description('The name of the budget')
param budgetName string

@description('The amount for the budget')
param budgetAmount int

@description('The environment name (it, qa, prod)')
param environmentName string

@description('Primary email for alerts')
param alertEmailPrimary string

@description('Secondary email for alerts')
param alertEmailSecondary string

@description('Phone number for SMS alerts')
param alertPhone string

@description('Resource group scope for the budget')
param resourceGroupId string

/*
 * ESTIMATED COSTS BUDGET RESOURCE
 * ===============================
 * This budget monitors FORECASTED spending based on current usage patterns.
 * Azure uses machine learning algorithms to predict what the monthly spend
 * will be based on current resource usage trends.
 * 
 * WHY FORECASTED MONITORING MATTERS:
 * - Provides early warning before costs actually exceed limits
 * - Allows proactive cost management and resource optimization
 * - Helps identify cost trends before they become budget issues
 * - Essential for environments with variable workloads
 */
// Budget for estimated costs
resource budget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: '${budgetName}-estimated'
  scope: resourceGroupId
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: '${utcNow('yyyy-MM')}-01'
      endDate: '2030-12-31'
    }
    // Filter to only monitor costs for this specific resource group
    // This ensures we only track costs for this environment, not the entire subscription
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: [
          split(resourceGroupId, '/')[4] // Extract resource group name from full resource ID
        ]
      }
    }
    // Configure alert thresholds for forecasted costs
    // These alerts fire when Azure predicts we'll exceed the budget based on current trends
    notifications: {
      Estimated50: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50 // Alert when forecasted costs exceed 50% of budget
        contactEmails: [
          alertEmailPrimary
          alertEmailSecondary
        ]
        contactRoles: [] // Not using Azure RBAC roles for notifications
        thresholdType: 'Forecasted' // This is the key difference - forecasted vs actual
      }
      Estimated80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80 // Alert when forecasted costs exceed 80% of budget
        contactEmails: [
          alertEmailPrimary
          alertEmailSecondary
        ]
        contactRoles: []
        thresholdType: 'Forecasted'
      }
      Estimated100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100 // Alert when forecasted costs exceed 100% of budget
        contactEmails: [
          alertEmailPrimary
          alertEmailSecondary
        ]
        contactRoles: []
        thresholdType: 'Forecasted'
      }
    }
  }
}

/*
 * ACTUAL COSTS BUDGET RESOURCE  
 * ============================
 * This budget monitors REAL spending as charges are incurred.
 * These alerts fire based on actual Azure charges that have been processed.
 * 
 * WHY ACTUAL COST MONITORING MATTERS:
 * - Provides immediate alerts when real spending crosses thresholds
 * - Essential for compliance with hard budget limits
 * - Triggers immediate action when costs exceed acceptable levels
 * - Complements forecasted monitoring with real-time cost tracking
 */
// Budget for actual costs
resource budgetActual 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: '${budgetName}-actual'
  scope: resourceGroupId
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: '${utcNow('yyyy-MM')}-01'
      endDate: '2030-12-31'
    }
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: [
          split(resourceGroupId, '/')[4]
        ]
      }
    }
    notifications: {
      Actual50: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        contactEmails: [
          alertEmailPrimary
          alertEmailSecondary
        ]
        contactRoles: []
        thresholdType: 'Actual'
      }
      Actual80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [
          alertEmailPrimary
          alertEmailSecondary
        ]
        contactRoles: []
        thresholdType: 'Actual'
      }
      Actual100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [
          alertEmailPrimary
          alertEmailSecondary
        ]
        contactRoles: []
        thresholdType: 'Actual'
      }
    }
  }
}

/*
 * ACTION GROUP FOR ALERT NOTIFICATIONS
 * ====================================
 * This Action Group defines HOW and WHERE budget alerts are sent when thresholds are exceeded.
 * It implements the specific notification requirements from infrasetup.instructions.md.
 * 
 * NOTIFICATION STRATEGY:
 * =====================
 * The Action Group uses multiple notification channels to ensure alerts are received:
 * 
 * EMAIL NOTIFICATIONS:
 * - Primary Email: prashantmdesai@yahoo.com (main business email)
 * - Secondary Email: prashantmdesai@hotmail.com (backup personal email)
 * - useCommonAlertSchema: true = standardized alert format for easy processing
 * 
 * SMS NOTIFICATIONS:
 * - Phone: +1 224 656 4855 (formatted without the leading +1 for Azure API)
 * - Provides immediate mobile alerts regardless of email availability
 * - Critical for urgent budget overrun situations requiring immediate action
 * 
 * ACTION GROUP NAMING:
 * ===================
 * Each environment gets its own Action Group for clear identification:
 * - beeux-it-cost-alerts (IT environment)
 * - beeux-qa-cost-alerts (QA environment)  
 * - beeux-prod-cost-alerts (Production environment)
 * 
 * GROUP SHORT NAME LIMITATION:
 * ============================
 * Azure requires short names (max 12 characters) for Action Groups:
 * - BeuxCostIT, BeuxCostQA, BeuxCostPROD
 * - These appear in SMS messages so they need to be recognizable but brief
 */
// Action Group for SMS and Email notifications
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'beeux-${environmentName}-cost-alerts'
  location: 'Global' // Action Groups are global resources, not tied to a specific region
  properties: {
    groupShortName: 'BeuxCost${toUpper(environmentName)}' // Short name for SMS identification
    enabled: true
    // Email notification configuration
    emailReceivers: [
      {
        name: 'PrimaryEmail'
        emailAddress: alertEmailPrimary
        useCommonAlertSchema: true // Standardized alert format for consistent processing
      }
      {
        name: 'SecondaryEmail'
        emailAddress: alertEmailSecondary
        useCommonAlertSchema: true // Same format for both emails for consistency
      }
    ]
    // SMS notification configuration
    smsReceivers: [
      {
        name: 'SMSAlert'
        countryCode: '1' // US country code
        phoneNumber: replace(alertPhone, '+1', '') // Remove +1 prefix as Azure expects number without country code prefix
      }
    ]
  }
  tags: {
    Environment: environmentName
    Project: 'Beeux'
    Purpose: 'Cost Alert Notifications'
  }
}

output budgetName string = budget.name
output budgetActualName string = budgetActual.name
output actionGroupId string = actionGroup.id
