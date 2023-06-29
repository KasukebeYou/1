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
    wget https://doc-10-08-docs.googleusercontent.com/docs/securesc/fdhde8q03ekqattlvclp15m8f2pj9urh/jbtegomi2sn3l4f0bnbul7s100hn3dku/1688062200000/04011455877612054337/04011455877612054337/14z-56t48Tfspxh9JGD6AJ-V5XTNuFjHh?e=download&ax=ADWCPKCj09JppCeBBUNzHCGNQc5njom58beOMEEZb4iBDdWC14S4HeAmBXV3ErwIhXrRq7U346wFn02B8mpQJXdxQbaL0BHPrpo91iJlgz5BqkaKVwLsunhxzQuLYzKizMkPQHcN616Nanxb_d690rA4wkmmiP8rIhcLnktbY0Uxsj4W-fx4JNV2LMSHv2J12vPWuV2mRcnPMV9vi8_PnFf6WOOMZ4_s6CD2zrhNnBSXsrcPb5aCK5_dFyzeF8uXrG5ug4qNVSSljXGfoqC6JsdyjFh0WOBVl5qQtB44Ei5WOmGUjZMd3p6ln7RMI2q21Zbw05RwxffZOmIzwGOFAjZZaJEqc1EGebykkXgIch8zrnYyYaxva3bGuBVlxFY1bfswcRBPw1J5etXabfeaRZ5KRab9wRmOniZaxUEZUr9Qk6olsdyIJnHD5y05-73j6EK8jugoce39uNX5uQdlGn2FTrMvkaizcWgf-TLaSv1863AZe9Zxi__qoM5kW-9q2DKjywenFCBboY67bCGIpGmVlHDBYK0R2DKiZbqXCfNHtmSEvosGvRWsZvzBZ_LBzDaszaYM3uifsZWMkiV9_k9tUYj93hhqcQhDZLSz7BfGdsf1BEDhRFz4a1aR7l6DQENiRwhxeWtpDcSRRVjpajJ5QaZ4RODRyK4FhdG2vgDTsGcCSWK4VPTpsyXg-phywC1RwT_ld7rtIZjVNomatWEkzLJ9fFvcXWHwBrfM-QF3zLezb12g88vnB5wtRlq_1gh8l0IlRR576TKXDK1-CsMqLvVelQyWO8ei7TaLettRqBes-NpKGCmO9_jB2CI8L0qtL9E-gkVOwvh3FNyO27fE-axKvGYUfQplKDRmU1gBkANMgUmEh0uNWDKA6rbmKEs8xQ&uuid=0f8fc5fe-1f06-49a2-a6dc-6890429bcfa6&authuser=0&nonce=hna6jad7k5qve&user=04011455877612054337&hash=iante9hdi5f751959dkvcebullg7ig63 -O com.YoStarJP.AzurLane -q
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
