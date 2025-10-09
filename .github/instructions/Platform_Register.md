---
applyTo: '**'
---

# BeEux Word Learning Platform - Platform Register

## 📋 **PLATFORM COMPONENT REGISTRY**

**Version**: 1.0  
**Date**: August 31, 2025  
**Author**: Platform Architecture Team  
**Status**: ACTIVE REGISTRY  

---

## 🎯 **Purpose**

This document serves as the **authoritative registry** for all platform components and their assigned Four Letter Acronyms (FLAs). All platform components MUST be registered here with unique FLAs before deployment.

### **FLA System Rules**
- **Length**: Exactly 4 characters (no more, no less)
- **Uniqueness**: Each FLA MUST be unique across the entire platform
- **Case**: ALL UPPERCASE letters only
- **Format**: Letters only (no numbers or special characters)
- **Consistency**: Use the same FLA across all documentation, configuration, and operational references

---

## 🏗️ **PLATFORM INFRASTRUCTURE COMPONENTS**

| Component # | Component Name | FLA | Kubernetes or Docker-Compose Based | Category | Purpose |
|-------------|----------------|-----|-------------------|----------|---------|
| **1** | **Spring Cloud Vault** | **SCSM** | docker-compose.scsm-vault.yml | Secrets Management | HashiCorp Vault for secrets storage and management |
| **2** | **Spring Cloud Config Server** | **SCCM** | docker-compose.sccm-sccm-config-server.yml | Configuration Management | Centralized application configuration management |
| **3** | **Spring Cloud Eureka** | **SCSD** | docker-compose.scsd-eureka.yml | Service Discovery | Service registry and discovery |
| **4** | **Spring Cloud Gateway Cluster** | **SCGC** | Kubernetes | API Gateway | API gateway and routing |
| **5** | **PostgreSQL Cluster** | **WDAT** | docker-compose.wdat-postgres-cluster.yml | Database | Primary database cluster (Word Data Access Tier) |
| **6** | **Redis Cache** | **WCAC** | docker-compose.wcac-redis-cluster.yml | Caching | Distributed caching layer (Word Cache Access Control) |
| **7** | **Kafka Cluster** | **WEDA** |  | Message Queue | Event processing and messaging (Word Event Distribution Architecture) |
| **8** | **NGINX Load Balancer** | **NGLB** | kubernetes | Load Balancer | HTTP/HTTPS load balancing and reverse proxy |
| **9** | **Keycloak Authorization Server** | **KIAM** | kubernetes | Authentication | OAuth2 and OpenID Connect (OIDC) authentication, Identity and Access Management|
| **10** | **Spring Batch + Quartz** | **SCBQ** | kubernetes | Batch Processing | Scheduled batch processing and job scheduling |
| **11** | **ELK Stack** | **WELK** | kubernetes | Log Aggregation | Elasticsearch, Logstash, Kibana (Word ELK) |
| **12** | **Workflow, Rules and BPMN** | **WBPM** | kubernetes | Business Process | Camunda workflow engine and Drools rules engine |
| **13** | **Postfix SMTP Server** | **pfix** | kubernetes | SMTP Email Server | Email notification service | Custom image built by layering recent stable version of postfix on top of official dockerhub linux image (1 node)
| **14** | **Observability Stack** | **WOBS** | kubernetes | Monitoring | Prometheus, Grafana, Zipkin/OTel, Boot Admin monitoring stack |
| **15** | **Continuous Integration and Deployment** | **WCID** | kubernetes | Continuous Integration and Deployment using Github Actions Runner|
| **16** | **Infrastructure Orchestration** | **WIOR** | kubernetes | Infrastructure Orchestration (Kind 1 master node, 1 worker node, Helm, kubectl, docker managed storage volume) |
| **20** | **API Documentation** | **SWAG** | kubernetes | Swagger User Interface for API Documentation |
| **21** | **Vector Database** | **WVDB** | kubernetes | Weviate Vector Database semitechnologies/weaviate|
| **22** | **Shared Azure Files** | **SHAF** | Azure Files (Standard) | Azure Files (Standard) to share files between the VMs|

---

## 🚀 **APPLICATION COMPONENTS**

| Component # | Component Name | FLA | Kubernetes or Docker-Compose Based | Category | Purpose |
|-------------|----------------|-----|-------------------|----------|---------|
| **17** | **Word APIs** | **WAPI** | Kubernetes based | REST APIs | All REST APIs for word application (Spring framework based) |
| **18** | **Word End User Interface** | **WEUI** | Kubernetes based | User Interface | End user interface (Angular framework based) |
| **19** | **Word Admin User Interface** | **WAUI** | Kubernetes based | Admin Interface | Admin user interface (Angular framework based) |

---

## 📊 **FLA CATEGORY BREAKDOWN**

### **Spring Cloud Components (SC)**
- **SCSM** - Spring Cloud Secrets Management (Vault)
- **SCCM** - Spring Cloud Configuration Management (Config Server)
- **SCSD** - Spring Cloud Service Discovery (Eureka)
- **SCGC** - Spring Cloud Gateway Cluster
- **SCAS** - Spring Cloud Authorization Server
- **SCBQ** - Spring Cloud Batch + Quartz

### **Word Infrastructure (W)**
- **WDAT** - Word Data Access Tier (PostgreSQL)
- **WCAC** - Word Cache Access Control (Redis)
- **WEDA** - Word Event Distribution Architecture (RabbitMQ)
- **WELK** - Word ELK Stack
- **WBPM** - Word Business Process Management
- **WOBS** - Word Observability Stack
- **WCID** - Word Continuous Integration and Deployment
- **WIOR** - Word Infrastructure Orchestration

### **Word Applications (WA/WE)**
- **WAPI** - Word APIs
- **WEUI** - Word End User Interface
- **WAUI** - Word Admin User Interface

### **Third-Party Components (NG/SE)**
- **NGLB** - NGINX Load Balancer
- **SEMS** - Simple Email Management Service

---

## 🔍 **FLA USAGE STANDARDS**

### **Documentation References**
Always include FLA when referencing components:
- ✅ "Vault (SCSM)" 
- ✅ "Config Server (SCCM)"
- ✅ "PostgreSQL Cluster (WDAT)"
- ❌ "Vault" (missing FLA)

### **Configuration Files**
Include FLA in comments for clarity:
```yaml
# SCSM (Vault) configuration
spring:
  cloud:
    vault:
      # ... vault configuration
```

### **Monitoring and Dashboards**
Use FLA in dashboard names and alert configurations:
- Dashboard: "SCSM Vault Secrets Monitoring"
- Alert: "WDAT PostgreSQL Cluster Health"
- Metric: "WCAC Redis Cache Performance"

### **Logging Standards**
Include FLA in log entries for component identification:
```
[SCSM] Vault secret rotation completed successfully
[SCCM] Configuration refresh broadcast initiated
[WOBS] Observability stack health check passed
```

### **Operational Procedures**
Reference components by both full name and FLA:
- "Restart the Observability Stack (WOBS) services"
- "Validate Spring Cloud Config Server (SCCM) connectivity"
- "Check PostgreSQL Cluster (WDAT) replication status"

### **Script Naming Convention**
All operational scripts MUST use FLA-based naming:
```
Pattern: <FLA>-<component-name>-<subcomponent-name>-<purpose>-<function>-<detail>.sh

Examples:
- scsm-vault-secrets-rotation-monitoring.sh
- sccm-sccm-config-server-environment-validation.sh
- wdat-postgres-cluster-backup-verification.sh
- wobs-observability-stack-performance-check.sh
```

---

## ➕ **COMPONENT REGISTRATION PROCESS**

### **Adding New Components**
When adding new platform components:

1. **Choose Unique FLA**: Ensure 4-letter acronym is not already in use
2. **Follow Naming Pattern**: Use appropriate category prefix (SC, W, NG, SE)
3. **Update Registry**: Add entry to this document with all required information
4. **Validate Uniqueness**: Confirm no conflicts with existing FLAs
5. **Update Documentation**: Reference new component with FLA consistently

### **Component Information Required**
For each new component, provide:
- Component number (sequential)
- Full component name
- Unique 4-letter FLA
- Docker compose filename
- Category classification
- Purpose/description

---

## 🔐 **SECURITY AND COMPLIANCE**

### **FLA Security Standards**
- FLAs are **non-sensitive identifiers** and can be used in public documentation
- FLAs MUST be used consistently across all environments (dev, IT, QA, production)
- Secret naming and operational procedures MUST reference appropriate FLAs
- All security validation scripts MUST use FLA-based naming convention

### **Audit and Compliance**
- This registry serves as the authoritative source for platform component identification
- All operational documentation MUST reference components using registered FLAs
- Security audits MUST validate that all components are properly registered
- Compliance reporting MUST use standardized FLA references


## 🔄 **CHANGE MANAGEMENT**

### **Registry Updates**
- All changes to this registry MUST be reviewed and approved
- FLA assignments are **permanent** and should not be changed once deployed
- New component additions require validation of FLA uniqueness
- Component removal requires deprecation process with impact analysis

### **Version Control**
- This document is version controlled and tracked
- All changes must include justification and approval
- Component lifecycle changes must be documented
- Historical FLA assignments must be maintained for audit purposes

---

## 📞 **REGISTRY CONTACT**

- **Platform Architecture Team**: Primary maintainers
- **DevOps Team**: Secondary reviewers for operational impact
- **Security Team**: Security validation and compliance review

---

**REMEMBER**: Every platform component MUST be registered in this document with a unique FLA before deployment. This registry is the single source of truth for all platform component identification.

---

**Last Updated**: August 31, 2025  
**Next Review**: Quarterly or when new components are added
