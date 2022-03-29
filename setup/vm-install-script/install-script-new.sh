#!/bin/bash

echo ".........----------------#################._.-.-INSTALL-.-._.#################----------------........."
PS1='\[\e[01;36m\]\u\[\e[01;37m\]@\[\e[01;33m\]\H\[\e[01;37m\]:\[\e[01;32m\]\w\[\e[01;37m\]\$\[\033[0;37m\] '
echo "PS1='\[\e[01;36m\]\u\[\e[01;37m\]@\[\e[01;33m\]\H\[\e[01;37m\]:\[\e[01;32m\]\w\[\e[01;37m\]\$\[\033[0;37m\] '" >> ~/.bashrc
sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc
source ~/.bashrc

apt-get autoremove -y  #removes the packages that are no longer needed
apt-get update
sudo ufw disable
sudo ufw reset -y
systemctl daemon-reload

echo ".........----------------#################._.-.-DOCKER-.-._.#################----------------........."
sudo apt-get install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker

cat > /etc/systemd/system/docker.service.d/docker.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOF

echo ".........----------------#################._.-.-KUBERNETES-.-._.#################----------------........."
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
sudo apt-get install kubeadm kubelet kubectl -y
apt-mark hold kubeadm kubelet kubectl
sudo apt install python3-pip -y
pip3 install jc

### UUID of VM
### comment below line if this Script is not executed on Cloud based VMs
jc dmidecode | jq .[1].values.uuid -r

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
mkdir -p /etc/systemd/system/docker.service.d

sudo swapoff -a
sudo swapoff -a && sed -i '/swap/d' /etc/fstab
sudo sed -i '/ swap / s/^/#/' /etc/fstab
sudo kubeadm init --apiserver-advertise-address=172.31.19.175 --ignore-preflight-errors all --pod-network-cidr=10.244.0.0/16 --token-ttl 0

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

systemctl daemon-reload
systemctl restart docker
systemctl enable kubelet
systemctl start kubelet

echo ".........----------------#################._.-.-DEPLOY POD NETWORK-.-._.#################----------------........."
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl get pods --all-namespaces


echo ".........----------------#################._.-.-Java and MAVEN-.-._.#################----------------........."
sudo apt install openjdk-8-jdk -y
java -version
sudo apt install -y maven
mvn -v

echo ".........----------------#################._.-.-JENKINS-.-._.#################----------------........."
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install -y jenkins
systemctl daemon-reload
systemctl enable jenkins
sudo systemctl start jenkins
sudo usermod -a -G docker jenkins
echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

echo ".........----------------#################._.-.-COMPLETED-.-._.#################----------------........."


