output "master_ip" {
  value = module.k8s_master.ip
}

output "worker_ips" {
  value = [
    module.k8s_worker1.ip,
    module.k8s_worker2.ip,
    module.k8s_worker3.ip
  ]
}
