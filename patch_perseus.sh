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
    wget https://doc-10-08-docs.googleusercontent.com/docs/securesc/fdhde8q03ekqattlvclp15m8f2pj9urh/otdr234nt5itibi4ik3clu8eq16gr1jo/1688064600000/04011455877612054337/04011455877612054337/14z-56t48Tfspxh9JGD6AJ-V5XTNuFjHh?e=download&ax=AGtFMPUqhOVPPQsYeZc6MaiLulhnEOhLtKPxS3abuzj7NLLZuOY2XpATWlfq7QDSAg-aYE2WzmswlXsUgGAlvrjV3WKSuDDXeauggA-giW2m1g0i9-7SFdVF7TIb8nqSflDj8HOnNs6uFm-pry7SB-YC9U2vuCnhnoyCen37be_gxGBBOGl3avWR39tLJcT2P_5majUGtt1YPqLAVi4oB2h3SuYPkOVloDhXBuBLnDwyybZUFPn9VEJy5PaUSX0sz1NdlECpC-6XLl7ynZKDmJkNqScd9Vn0ddvcg09lBVw0imQ3S0aGWE055rOBt8aGG17VOcq0vP7RNiIfnTPKfEapBls8Ihz5Vl1DW3ftlXGdkoZMBwh8tm1itvSuCst1bgZSLzmBFQ_adZaan1dFPXOlQyzfHO3NOfq6u1MKkaJh5t_5VImhK6WSliqkWetyay7ZnnBP8x67miR47qXBHwv_ZrO28ot0Cmu9sCi3n-dOfW7gk_p8aJTTNfdUx8wt0lc_p7d7PqQ58YLOHp981_b8opg15U__p8Av5Ph276JmniYDNXOetbniteutEBcHwzq6dWTIHjom2BQCaDBHij4ykyo2Po0-jvb6be8pabyzHb6fg27tp8JmQjRJyHLL3TCCL1zTl6qxgBuXoU9-59dyZ5kf6epTfJtiEImyMpfE3jHVIUi_YT_i8STnqwN2QNXZ_CooYLfoxpZGU_xuerLVA9fGh-rMn4dgFfEv9hM6ExLbUU38QMcalZMKpucMx05TPskrHH-LHUiR_KxehFanKb11_W5M3bu59DYOO4DsCqYzdQx0KFqdHy5h75i9Lo3KnwG0CAMEqzxUm1MALeYkebX1RuX603YMKpj9e7XsZEPjW0giWMnCunc_j7drWXjJHQ&uuid=1e5a7556-9514-461d-9051-c223346df31a&authuser=0 -O com.YoStarJP.AzurLane -q
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
