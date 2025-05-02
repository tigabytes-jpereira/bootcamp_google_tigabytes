output "backend_vm_public_ip" {
  value       = google_compute_instance.backend_vm.network_interface.0.access_config.0.nat_ip
  description = "IP público da VM do backend"
}

output "frontend_vm_public_ip" {
  value       = google_compute_instance.frontend_vm.network_interface.0.access_config.0.nat_ip
  description = "IP público da VM do frontend"
}

output "frontend_url" {
  value       = "http://${google_compute_instance.frontend_vm.network_interface.0.access_config.0.nat_ip}:5000"
  description = "URL do frontend"
}