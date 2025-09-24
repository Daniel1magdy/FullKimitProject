# 🚀 DevOps Project: Containerized Apps on AWS EKS with Jenkins, Terraform, Prometheus & Grafana  

This project demonstrates a **complete DevOps pipeline** for deploying containerized applications on **Amazon EKS** using **Infrastructure as Code (Terraform)** and **Jenkins** for CI/CD automation.  
It also integrates **Prometheus** and **Grafana** to provide observability into system performance and reliability.  

---

## 🔹 Key Features  

- **Applications**:  
  - Frontend → Node.js/Express + static HTML  
  - Backend → Node.js/Express API  

- **Containerization**:  
  - Both applications are Dockerized for portability and consistent deployments.  

- **Infrastructure as Code (IaC)**:  
  - Terraform provisions AWS resources: VPC, subnets, IAM roles, and an EKS cluster.  

- **CI/CD Pipeline**:  
  - Jenkins automates Docker image builds, pushes to Amazon ECR, and Kubernetes deployments to EKS.  

- **Kubernetes Deployments**:  
  - Manifests define **Deployments**, **Services**, and **Ingress** for frontend and backend apps.  

- **Monitoring**:  
  - Prometheus scrapes metrics from cluster components.  
  - Grafana provides rich dashboards for visualization.  

---

## 🔹 Workflow  

1. **Code Commit (GitHub)** → triggers Jenkins pipeline.  
2. **CI/CD Pipeline** → builds Docker images & pushes them to **Amazon ECR**.  
3. **Terraform** → provisions AWS networking & EKS cluster.  
4. **Kubernetes** → deploys frontend & backend services to EKS.  
5. **Prometheus & Grafana** → monitor cluster health, app performance, and resource usage.  

---

## 🔹 Project Outcomes  

- ✅ End-to-end automated containerized app deployment to **AWS EKS**.  
- ✅ Scalable & reproducible infrastructure using **Terraform**.  
- ✅ CI/CD best practices with **Jenkins workflows**.  
- ✅ Full-stack monitoring with **Prometheus & Grafana dashboards**.  

---
