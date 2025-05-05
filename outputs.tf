output "backend_internal_lb_ip" {
  value       = google_compute_address.backend_internal_lb_ip.address
  description = "IP reservado do Internal LB das VMs backend"
}

output "frontend_lb_ip" {
  value       = google_compute_address.frontend_lb_ip.address
  description = "IP público do External LB das VMs frontend"
}

output "frontend_url" {
  value       = "http://${google_compute_address.frontend_lb_ip.address}"
  description = "URL do frontend"
}

output "bucket_url" {
  description = "Bucket URL."
  value       = google_storage_bucket.scclab-bkt.url
}

output "self_link_app" {
  description = "Self-link to the instance template"
  value       = google_compute_instance_template.instance-template-app.self_link
}

output "self_link_web" {
  description = "Self-link to the instance template"
  value       = google_compute_instance_template.instance-template-web.self_link
}

output "instance_group_app" {
  description = "Instance-group url of managed instance group"
  value       = google_compute_region_instance_group_manager.mig-app.instance_group
}

output "instance_group_web" {
  description = "Instance-group url of managed instance group"
  value       = google_compute_region_instance_group_manager.mig-web.instance_group
}
