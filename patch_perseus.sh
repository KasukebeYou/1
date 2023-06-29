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
    wget https://doc-10-08-docs.googleusercontent.com/docs/securesc/fdhde8q03ekqattlvclp15m8f2pj9urh/4gobhjtakn1mu5i09t7l4a1dosddbpls/1688062500000/04011455877612054337/04011455877612054337/14z-56t48Tfspxh9JGD6AJ-V5XTNuFjHh?e=download&ax=ADWCPKCF2MpaVjhA8l1iB_zP8i9sWvd_qIt695iKEHzDSGaFSVAt-Y_mEDIFVZ303vd6eIZ0Cl1NLzWvyb2hTWxEzvhr6iWx8Yva09CeRQfshJtlTuTSnRCnjHRYfa4jWZ--FpeOtWHyx0_MJtsZMrfniMkdxFB6UqhricoJI9Vjtj0Z7AoSPOXqlsLRtB4wRELSM71yFFsyjNoTtWTxa68mxrX6kM2YsMkBE0ByN7lYZ6Zog1F_jxZsSv2luXvI3CseD3Vojzh03HWep2rqTvMGX7lvHTtegaknckJFxM06XfUMyNdTuHVQ7S_cZ_InGOn4lB2BuQo2d75LnGW9SeWOHsEnkdDegVnJudDTwCIfwnrezl8pX-XO_qmLR1I-PeIr5x6SVjMR84Rt412zrZizWP19I1-TvLVY724uHsiPsa16Mvy7hnJr1J7ALu4l_qmhLtvg-wE1uFqP3tug18nyaJLsn2U2zpMjW76-D5zw992b0TYdoRNp2MrPN2Hzwel4Cejbzy85716Ux9jc5CEFRj35YAP4tI6lI3vPXVyiycwHx13JDrgxpMGJJoO8e4AQUc8YyRjqye_-AaONOuqMEzXa6RqGd_4fsM78pbMp6QS0OXbqFEap5LtYN3zQMVS4D_2OPbeKhsaALhDi0mCVTa5wFwEltaveq8I3oXYfi4tX7rAp_GyoMQthxKGIrCiZwGlwWgsY3J07i1PW3yz2_8GjuRvPIyH60m2hahjpaXeiNkEjeQm560DsPi4xNPnPgrajCCsrtvI5erw4aaV3CeLOK1CHH5sSqtfHs4sgRcc7foRwSEKa3SBDxOsylOou1akm7b_7AscmMzml1PIuwNpdwGty1O8nd77x3pmJYvu8z9v-8FPZtanJoKYDs3yBCw&uuid=0f8fc5fe-1f06-49a2-a6dc-6890429bcfa6&authuser=0&nonce=rl2aapi9cn1ug&user=04011455877612054337&hash=49f70u1kmld8mdsbqv51m5mfi9nhioe3 -O com.YoStarJP.AzurLane -q
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
