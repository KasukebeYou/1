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
    wget https://doc-0c-cc-docs.googleusercontent.com/docs/securesc/fdhde8q03ekqattlvclp15m8f2pj9urh/gu485nbtlju2ujntc5jcv425slvcs0ta/1688061525000/05309739250916540937/04011455877612054337/19z9SgkJ28XHxpvjglQ6TTLW-K0qvWWBx?e=download&ax=ADWCPKArd3YFvevszdGMP5FcjVWkiosgVZsetajS7Pocekf4LASAVXsGE99VACkBOWXoT-MhgG1NyUGpuMarJt3Z6beOnX-nmynLTnHfQpCg5wpAoy8JzcwrKlmjb1Qjm3pSzj26NlP2f5DYubbAFdUW_1ug1UunXKqHaGM2TjlZnCzujmLpNTQrjOWgLuFRpSigq19SkevA9pfdWIU7S3hrAMU7pDfZBq2Km0NgLu3PylooixpyBHlihUcveok4RNlVaqeEoz1wjwYHyAIRauyvjpRKv76UTAxCdxAImnHjx3ByLPpUS3K0QrNQdjQicC1KF-oZ4HLDnk8LPZMnlmRG-KwkpfABzzntHf6ABG2jKKxhDsIj5ZSmf7ixvANtNDIcTos8TRUWclTcIzwUQUUfnlTzIjiGPue6mqKHekwA8JF8PGfBuGVeUQlCmMZH19B-nBdAzFFOLY_NWldaRQp1pcTcIg5wj_a14qPMFZGul2flM93JF0PSd2Vgoc20fGcYAyGYobwRrH5DAmawu8stj41GncfRyP0RQgI4I28qQmyhbTi9n7RGd6esZyy007JM_cCboEPa7ssTRHYupZUEYaGKv4MleHC-6Pb-vH4tA6cGZixJpdHhC0QAcpIK4oNnsvKkvrqcDH_YntiSF_i3ihVGV3BKM-naLFKPWPvZd5NvFBxjBaMfCjyFrmkuPKnxOqRv18RQGL83HwWlsfq23kr0D0yw3tmJHeNRNaT_MHoS2vIGVKs0ZpJgsmq1uMw_ZGhvRTNk95lVcCp97rzOjgkr6nvvFBIubVN_e8cSMJpQbllgTfHZKmUa5wjoYrqgFf-x9CyibSR8sPPukOb5H03OlY5ERlM0q4CS4Gyb6WSdUd50l4SOIeTgVziXEG9Jbg&uuid=9b610f36-974d-42a6-bb87-61e01bde82a3&authuser=0&nonce=ra1sr9craju6s&user=04011455877612054337&hash=1pvcf51buc6coit1lq6uljiogtif96tu -O com.YoStarJP.AzurLane -q
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
