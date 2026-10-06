# MicroK8s → Talos 移行計画

2026-10-06 開始。MicroK8s（Ubuntu 24.04、VM 810/820/830）の k8s クラスタを Talos Linux に置き換える。
判断の記録は [talos-migration-decisions.tsv](talos-migration-decisions.tsv)。

## 完了条件

- Talos 1.14.2 / Kubernetes 1.37.1 の 3 ノード（control plane 1 + worker 2）が Ready で、Terraform だけで作り直せる。
- lab-argo の全 Application が Synced / Healthy。
- 既存の SealedSecret 7 件が、作り直さずにそのまま復号される（sealed-secrets の鍵を移行）。
- CouchDB（Obsidian LiveSync）のデータが移行前と同じで、talaria.mercuryksm.net から同期できる。
- Loki の PV（Ceph RBD）と Prometheus の PV（NFS）も付け直し、過去のデータが見える。
- kubelet / etcd などの Talos サービスログが Loki に入る。

## 構成の決定

| 項目 | MicroK8s（旧） | Talos（新） |
|---|---|---|
| VM | 810 / 820 / 830、.181〜.183 | 同じ（旧 VM を削除してから作る） |
| テンプレート | noble-template（9000） | talos-template（9001、ceph-rbd 上、Image Factory の nocloud + qemu-guest-agent） |
| ノード構成 | hod = control plane、netzach / yesod = worker | 同じ（hod は Pod も載せる） |
| Pod / Service CIDR | 10.1.0.0/16 / 10.152.183.0/24 | 同じ（Talos 既定の 10.96.0.0/12 は Gateway の LB プール 10.100.0.0/28 と重なる） |
| Ceph RBD のマウント | krbd | krbd（Talos 1.14.1+ は aes256k 対応をバックポート済み、k8s-test で確認） |
| 構築 | Terraform + Ansible | Terraform（telmate + siderolabs/talos）+ Cilium / Argo CD のブートストラップ用 task |

## 手順

1. **検証（k8s-test 環境）**：yesod に Talos 1 台（VM 919）を立て、Cilium、ceph-csi（krbd）、静的 PV の付け直し、NFS、ログ転送を確かめた（2026-10-06 完了、削除済み）。
2. **IaC の整備**：Terraform の k8s 環境を Talos に置き換え、lab-cilium / lab-argo の Talos 対応を `talos` ブランチで用意する（旧クラスタの Argo CD は lab-argo の main を読むため、切り替えまで main には入れない）。
3. **切り替え**（旧クラスタの先行削除はユーザー了承済み）
   1. RBD イメージのスナップショットを取り、sealed-secrets の鍵を書き出す
   2. 旧クラスタを `terraform destroy` で削除する（Argo CD の Application は消さない。消すと PVC ごと削除される）
   3. lab-argo / lab-cilium の `talos` ブランチを main にマージする
   4. Talos クラスタを作り、鍵を入れてから Argo CD をブートストラップする
   5. PV を静的に付け直す（CouchDB、Loki、Prometheus）
   6. MicroK8s の Ansible ロールなどを片付ける

旧 VM は残さない（ユーザー了承済み）。データは RBD スナップショットと NFS 上のディレクトリに残る。

k8s 以外の VM / CT（talaria、primind、kasuminet、test-vm、gnosis、athanor）には触れない。

## ユーザー作業

- Tailscale 管理画面で、旧クラスタのデバイス（k8s-operator、grafana、argocd など）を削除する（同じホスト名を新クラスタが使うため）。
