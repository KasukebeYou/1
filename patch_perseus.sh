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
    wget https://doc-10-08-docs.googleusercontent.com/docs/securesc/fdhde8q03ekqattlvclp15m8f2pj9urh/d7pfeivg37b6c0qr2m3tvnmd13qc47ga/1688065125000/04011455877612054337/04011455877612054337/14z-56t48Tfspxh9JGD6AJ-V5XTNuFjHh?e=download&ax=ADWCPKC8nUz6x11x5gm5UXWkufjZXcKkca9QMcoRXui1_PAutKn7E4go5dROF-uq3npF7BRJcTEoSE07pqfPxlQQYZGVTAW2FMtKuodYOWR6N86_3YPZcpONHgjFpPtbcsXS0FiCBYwL1wPbiPC88bbtYRLMnkoLzplZ2OIDfM4Yfr1H4NL13cbKXIcTiFPMZu8B9-xpuMXh_xNzRcqbT0rizCSj38QSwIDOtiqDcFYWRus6CtQxRExWQQ55dILDFqmVpEFm3MlhcbtujXZoXLXbcculAM2E-_DZappr-7HVqbbEvt4FcYXYfqDR0CsDNUnwoHVgm7YxGdHSR3ag-b34uVPzjrlS8sr8DMYU8UX8bLmX7qAiJhkPOH04wKBueTYwLBqxaGcGiXzGC9bRFrlADlClYUyGkc1LSsrDMvaWE-HIpE5wfR1QefljEOMFN5ExWqxd4D3Gjdfvx9wU_o19xqW3hBmtKfMmH1b2dGykKKf9u2OSfsZgnIr1VloVQUZc3imGsVuIxBnBUDNMVmIZ1wCA1JsIOC8SZVB8ay_lCILzB9KoD3KZVsP4RzqiH93jb3NiH4hqU0p9ft-o-9qsR3aDOfW8wXe6WHq8PecjSq0sndxiBNBzmiT5FU_HuhmClBUlLCZVPkh_wY60VA9AKsQlzFrbkQAbvQHa57dlxzP9Z8DFtP4ZeuY1hAN9eEzcpKtaqDUJF-iNvRqDrPHQLD-zXG6b22RlSIfnaDad52E5P9TjpwD4rNUwWLS1ctWvorO9vY2iMtmVXsB_lEoWCHGc8GIfzWNYILDN7gPtrP-GejHnfsRwZlnhIscYcRPBjmdtcugcAR9ow0tXP74hM4SDKBADWJh-tjUfmD2ZJht80mkESE_-qo3nHUVIoi0srA&uuid=1e5a7556-9514-461d-9051-c223346df31a&authuser=0&nonce=du0s4hmdjtjik&user=04011455877612054337&hash=g5m7kf2n2f0hmguce36oq4q496ef1k6j -O com.YoStarJP.AzurLane.apk -q
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
