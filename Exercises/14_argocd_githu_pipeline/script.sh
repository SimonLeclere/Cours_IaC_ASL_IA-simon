# 1. Mise à jour de l'application-controller (StatefulSet)
kubectl patch statefulset argocd-application-controller -n argocd --type strategic -p '
spec:
  template:
    spec:
      dnsPolicy: "None"
      dnsConfig:
        nameservers:
          - 10.96.0.10
          - 8.8.8.8
          - 8.8.4.4
        searches:
          - argocd.svc.cluster.local
          - svc.cluster.local
          - cluster.local
        options:
          - name: ndots
            value: "2"
'

# 2. Mise à jour du repo-server (Deployment)
kubectl patch deployment argocd-repo-server -n argocd --type strategic -p '
spec:
  template:
    spec:
      dnsPolicy: "None"
      dnsConfig:
        nameservers:
          - 10.96.0.10
          - 8.8.8.8
          - 8.8.4.4
        searches:
          - argocd.svc.cluster.local
          - svc.cluster.local
          - cluster.local
        options:
          - name: ndots
            value: "2"
'

# 3. Redémarrage des composants pour appliquer les changements
kubectl rollout restart statefulset argocd-application-controller -n argocd
kubectl rollout restart deployment argocd-repo-server -n argocd

# 4. Vérification du statut du déploiement
kubectl rollout status statefulset argocd-application-controller -n argocd
kubectl rollout status deployment argocd-repo-server -n argocd

# [!IMPORTANT] Vérifiez que l'IP 10.96.0.10 correspond bien à l'IP du service kube-dns ou coredns dans votre cluster:
(kubectl get svc -n kube-system)