#!/bin/bash
USERHOME="$HOME"
pwd="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
DIDUPDATE=0
LATEST_KUBESPRAY=$(jq -r 'map(select(.prerelease != true)) | first | .tag_name' <<< $(curl --silent "https://api.github.com/repos/kubernetes-sigs/kubespray/releases"))
if [[ ! -d "${USERHOME}/.HandyHost/aktData/kubespray" ]] ; then
  mkdir -p "${USERHOME}/.HandyHost/aktData/kubespray" && \
  cd "${USERHOME}/.HandyHost/aktData/kubespray" && \
  git clone https://github.com/kubernetes-sigs/kubespray.git . && \
  git checkout "$LATEST_KUBESPRAY" && \
  virtualenv --python=python3 venv && \
  . venv/bin/activate && \
  pip3 install -r requirements.txt
else
  echo "kubespray already installed, check for updates" && \
  cd "${USERHOME}/.HandyHost/aktData/kubespray" && \
  git fetch --all && \
  LOCAL_KUBESPRAY=$(cd "$USERHOME/.HandyHost/aktData/kubespray" && git describe --tags )

  if [[ "$LOCAL_KUBESPRAY" == "$LATEST_KUBESPRAY" ]]; then
    echo "Kubespray is up to date"
  else
    echo "kubespray is out of date, updating" && \
    git fetch --all
    git checkout "$LATEST_KUBESPRAY"
    virtualenv --python=python3 venv && \
    . venv/bin/activate && \
    pip3 uninstall -y ansible && \
    pip3 install -r requirements.txt && \
    DIDUPDATE=1
  fi
fi
echo "kubespray update is done, checking akash for kubernetes updates."
#update k8s cluster whenever this script is ran
#it could either be called because kubespray needed updates
#alternately akash released a new version

AKASH_VERSION=$(/bin/bash "$pwd/getAkashLatestVersion.sh")

cd ${USERHOME}/.HandyHost/aktData && \
if [[ ! -d "${USERHOME}/.HandyHost/aktData/akashRepo" ]] ; then
  mkdir -p "${USERHOME}/.HandyHost/aktData/akashRepo" && \
  cd "${USERHOME}/.HandyHost/aktData/akashRepo" && \
  git clone https://github.com/ovrclk/akash.git . && \
  git checkout "$AKASH_VERSION"
else
  cd "${USERHOME}/.HandyHost/aktData/akashRepo" && \
  git fetch --all && \
  git checkout "$AKASH_VERSION"
fi

chown -R "$USERNAME:$USERGROUP" "${USERHOME}/.HandyHost/aktData/akashRepo"
#running all this in node per usual
#check if we have an inventory
# if [[ -s "$HOME/.HandyHost/aktData/inventory.yaml" ]] ; then
# 	echo "updating akash kubernetes cluster"
# 	echo "teardown cluster"
# 	/bin/bash "$pwd/teardownK8sCluster.sh"
# 	/bin/bash "$pwd/initK8sCluster.sh"
# 	/bin/bash "$pwd/postInitK8sCluster.sh"
# fi