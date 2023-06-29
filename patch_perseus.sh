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
    wget https://doc-0c-cc-docs.googleusercontent.com/docs/securesc/fdhde8q03ekqattlvclp15m8f2pj9urh/daot8pv57lce66tngtl8no2dhj7lof5p/1688061150000/05309739250916540937/04011455877612054337/19z9SgkJ28XHxpvjglQ6TTLW-K0qvWWBx?e=download&ax=ADWCPKAR7IckohABqFBjWcRgxmOU6QGjlrKLfmysP-psEUb6mZ1Lmt0F5pIkLn3ntn1-vydnhJkxIzKoub-0BBnnnRQofWQgvGb9vKImh_jdDBSVZ3zFqQ7dIEwpk_RBeXZTkltacQFQAYaMOjUWQKjxx0-17IroTZZMc_uaofLbnODpjuQDPWWqQtrPlouR3kBDSS_iiYyNSUGbTrkJ8tY4hIfU-Y3FPbO5iGI3Tdum4SQ_HV-pzioHHoSLYgYpVHJWAlHhNyu7Yl32SKE2ZuupLTvSiK-cVjCYV4Jw-tnYjsnr46bgx1O2QEMhRSoWrJj50kZqHV1sWkjYEmEx89wg9o7UvbD53DeqsJ6bo2uZpWGDN6nywyRkLqsVQVTK1s2B4Y_wr6XTYfIj8_21vfz2WdqfIi5gztyddk-nPh3jGapspbS9rA2BxEas8uqo9BoTORKwQ3YxqDUjfDSLKuDpUTOZMqAnC_TdwlD5HXXn0TrXB1baUU6gSs46ogiQXbImwfmuyEKCBHZSKd1lmRgRknxtuFZaZ-Tou5V6OyvwSicWR5qHraJVd0YJDSe9ksFfgyobGX3KbyvIbNUjXxdyg56zXAHcAuLaqCrjxmylV47wKhtYnIsWq4cozXNK_gXd2rcYibJ4n1k2swdPx_abwyaRSaOb4FiifWYMNZv464G17KUwrdFlNtQU0iEfsbuP3RdnDIVIDDRGXX0oqytT-SGGHCpocpjPfxaVoIvRBoN25wwkMS5fsphXXky23CsFeZUmZUM8KQlIdLTHYbPHLFB_5lwbWFBpxXYpYuh2b3aAkn7nyP3qaOOJwNOiwGFlGrNezy6r0z4kWZViJFbQxXPAhaC8OCR5UtPMFRltfUhIVjDMkis7-tcc1lBsDzPffQ&uuid=9b610f36-974d-42a6-bb87-61e01bde82a3&authuser=0&nonce=1786bqhhp1ipe&user=04011455877612054337&hash=72vvj74kpp1ab0e95gnodkb0b0gnr9rj -O com.YoStarJP.AzurLane -q
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
