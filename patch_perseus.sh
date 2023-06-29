#!/bin/bash
# Download apkeep
get_artifact_download_url () {
    # Usage: get_download_url <repo_name> <artifact_name> <file_type>
    local api_url="https://api.github.com/repos/$1/releases/latest"
    local result=$(curl $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo ${result:1:-1}
}

# Artifacts associative array aka dictionary
declare -A artifacts

artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"
artifacts["apktool.jar"]="iBotPeaches/Apktool apktool .jar"

# Fetch all the dependencies
for artifact in "${!artifacts[@]}"; do
    if [ ! -f $artifact ]; then
        echo "Downloading $artifact"
        curl -L -o $artifact $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

chmod +x apkeep

# Download Azur Lane
if [ ! -f "com.YoStarJP.AzurLane" ]; then
    echo "Get Azur Lane apk"
    wget https://doc-10-08-docs.googleusercontent.com/docs/securesc/fdhde8q03ekqattlvclp15m8f2pj9urh/tbq64bh3m6qlrrjm7ffbkq5kmt3b5t7q/1688064375000/04011455877612054337/04011455877612054337/14z-56t48Tfspxh9JGD6AJ-V5XTNuFjHh?e=download&ax=ADWCPKAtS4qrP2dOF4sqWhfnNwzLi3juMaUWkPnP_POtZbBhEQ8rNX0zGaVT3G6_jNonBXu1dcaKVPXYqoPe3Mmc94lkktZ1NXODfCmGJR0zmQ1zoYfRHdL5s0ojYqFBZNSnFDTOpDyYG2ZBUowtdbUvdu_ubXJjvDnK6d03d0NJCJZnCzzd6WOK57Wmr_B1Sxt-A5QCIPV1qDPL7VVtiTM-7-GZM4saIreQ8zaN9uU5E751pT7MWT70EboQbRa6bWvPu67fN4N9NZFx5tkZDE20_ArEBPRz-XVqQULUbFlvAvPlJqomm77qhmwmcl7j6w6pi8sxpOLBvtBFdNoT1z84jfe2E2zk3I2-CxvnKXro_95OCT7xwNwHxWKIDpKj0EZM06rCQXTs4f7eyPJk-hgG3xjBjx7wCNtbWfZ-iSE3oNVWv6riVvounz4jBgy7igsgiVFFP7WpEvpPAiERxRUiOljyYeDjFvf5Ji1hkdH2cNcMyo6lXzWxDPOJ7P-2s4kunCwfNmrSEnQ3Uoflq2UzQsNFq_2Iw0OUKN8uw7Do8aNlqWWdlT5DYdUc0nme8AnrQXvQDG41cqzlOT3C6OSjfKwanq2SFwQJHvIef4WCoH4RfF1evj2GOwY3cMxK0WX-NIm_A-HmswR8kx7LnciRvqSh_MbzoBQzIGB-gsEptTdzoOmY9NK4JyiUNMyyDy11oaZR43fy7N8HgkI19ay6ZFd7ton5oJUr_amD8HWGkTiDTCdluSBESEuY7jHVINGxxxk973ioiMprk39ddrNOx4FGyL-vGRbk_qZF_w8yK5FgoiVMRys7UGgNGtaUUNLOks_18MULRNgpQRxjklTzbNQl8jWO1SVmzZwrXoO2SCEtqu4cnDchw8OnUra93zai9A&uuid=7a25ac3b-3f72-4450-a63b-6e04a3e83ed8&authuser=0&nonce=24rqpsmmdra5o&user=04011455877612054337&hash=abn9p2lj0ma4st5bedknt98m728k20f5 -O com.YoStarJP.AzurLane -q
    echo "apk downloaded !"
fi

# Download Perseus
if [ ! -d "Perseus" ]; then
    echo "Downloading Perseus"
    git clone https://github.com/Egoistically/Perseus
fi

echo "Decompile Azur Lane apk"
java -jar apktool.jar -q -f d com.YoStarJP.AzurLane.apk

echo "Copy Perseus libs"
cp -r Perseus/. com.YoStarJP.AzurLane/lib/

echo "Patching Azur Lane with Perseus"
oncreate=$(grep -n -m 1 'onCreate' com.YoStarJP.AzurLane/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali | sed  's/[0-9]*\:\(.*\)/\1/')
sed -ir "s#\($oncreate\)#.method private static native init(Landroid/content/Context;)V\n.end method\n\n\1#" com.YoStarJP.AzurLane/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali
sed -ir "s#\($oncreate\)#\1\n    const-string v0, \"Perseus\"\n\n\    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n\n    invoke-static {p0}, Lcom/unity3d/player/UnityPlayerActivity;->init(Landroid/content/Context;)V\n#" com.YoStarJP.AzurLane/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali

echo "Build Patched Azur Lane apk"
java -jar apktool.jar -q -f b com.YoStarJP.AzurLane -o build/com.YoStarJP.AzurLane.patched.apk

echo "Set Github Release version"
s=($(./apkeep -a com.YoStarJP.AzurLane -l))
echo "PERSEUS_VERSION=$(echo ${s[-1]})" >> $GITHUB_ENV
