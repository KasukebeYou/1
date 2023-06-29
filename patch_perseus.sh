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
if [ ! -f "com.YoStarJP.AzurLane.apk" ]; then
    echo "Get Azur Lane apk"
    wget https://doc-10-08-docs.googleusercontent.com/docs/securesc/fdhde8q03ekqattlvclp15m8f2pj9urh/05cjm87q2e6vl74d0r9fg2l6d952cqq7/1688071875000/04011455877612054337/04011455877612054337/14z-56t48Tfspxh9JGD6AJ-V5XTNuFjHh?e=download&ax=ADWCPKDMk3KHD0kIhD2lAuNiT-pWZ7kcA7QB6hBCDISBxi2NrU29iTSkFcQHcy0oMVqIgWKtOkxhDhSbJJOhL5FfiTI9VIPmBCButii_G6Omb850pOB_o_z3r-Ip7J66DJpKkxQFgIY48_MNitPWG3qcK6I6Pqb14Xfh72A6FqhOXCQUJ67uEJnawzv3KGR8Mh-7VOXBWDnHtA-bXHROOu8WS2jPVNhUEI4F7qet1z3PgjGRgF3fDjbFNvED3D2-NTKC7rY8NkMV0doXWXcED0Gqu_JSGTOn3TGUgBeTeq_RRG5GdIRDT_slvvvJXnm75zMEQvlGo6PC1knDWE8OwBdq8440OVPUEI8HWt6rgqY-1Gyd1zZmxROVb72tvxTSdzI3VwWHXQL37-rJQNeMpRE8sreyKs86pOOEWM-STSRVwu-z6pyaui2M52e_pE-80NRjDrpq5he4dFAPr8M5tetbHOCzlDFpQhARMTZuL8oXh3LpUoxfVnJpUJHFrH5oxT5bJAvA9b1-7pajbSX_dvMzhMi9MwpfCH4OMv4TV4VtO_yKKcyE_91WJ2Gs7VMONCMCHZqxH4nDGyuknoDjWMSGP6A2iHzbC6Dtx4siVCIhKoR1MgWyga7eY9fiMIreD98GTGoKGCxCUUmby6gkhsx9bdjOyZh-h8IOCQ3mp4s6B3k6R902CwdHz510xoYnkRp-pNMlAHQ3fTuKPfyOcwLIdds06UhSHrFbLUSdHanzJS9U4hsTSy5LiDwwgL9l8Pf8k-oWZ55n6NFdBZodgRCfOFdE4rS5KL2r21yUJlsUqarvPA-8ba3EVGSbit9JBdASxcgCeufcIX7BuWxvbt96orsyt5t87TAOjME_9JH0etzRNwMt2ofILx-fKkWKQfYSIQ&uuid=a60cfd11-9c64-403c-8a9d-1ba3e4c38dc2&authuser=0&nonce=g4a6rpfduthiu&user=04011455877612054337&hash=sfpqilu9efkjuktppnn3p7tnnis21ki5 -O com.YoStarJP.AzurLane.apk -q
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
