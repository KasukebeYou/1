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
    wget https://dl-pc-zb-cf.pds.quark.cn/yBAafq5t/943499414/649da88bcc6f66b88b104dd98507ff2e5ed69f2f/649da88b2fb72501f08949b594d5c979f5cf1e6a?Expires=1688084387&OSSAccessKeyId=LTAIyYfxTqY7YZsg&Signature=aYf6cfKDxh6jYKUDX2mHZQEbzxo%3D&x-oss-traffic-limit=503316480&response-content-disposition=attachment%3B%20filename%3Dbase-7112.apk&callback-var=eyJ4OnNwIjoiMTk5IiwieDp0b2tlbiI6IjItYzBjNDU1NTE5NzQyODM5YTEzMmE5ZWY1ZGE1ZDg4ZTEtOC0xLTUwMC01NWE5NjMzODdkMjQ0ZTE3Yjc5ZDUzNjcyM2QwM2FkZS0wMTc5MDRkOThhOTIyYjE5MGFhYmU3N2NmNDc5MDVmZCIsIng6dHRsIjoiMjE2MDAifQ%3D%3D&callback=eyJjYWxsYmFja0JvZHlUeXBlIjoiYXBwbGljYXRpb24vanNvbiIsImNhbGxiYWNrU3RhZ2UiOiJiZWZvcmUtZXhlY3V0ZSIsImNhbGxiYWNrRmFpbHVyZUFjdGlvbiI6Imlnbm9yZSIsImNhbGxiYWNrVXJsIjoiaHR0cHM6Ly9hdXRoLWNkbi51Yy5jbi9vdXRlci9vc3MvY2hlY2twbGF5IiwiY2FsbGJhY2tCb2R5Ijoie1wiaG9zdFwiOiR7aHR0cEhlYWRlci5ob3N0fSxcInNpemVcIjoke3NpemV9LFwicmFuZ2VcIjoke2h0dHBIZWFkZXIucmFuZ2V9LFwicmVmZXJlclwiOiR7aHR0cEhlYWRlci5yZWZlcmVyfSxcImNvb2tpZVwiOiR7aHR0cEhlYWRlci5jb29raWV9LFwibWV0aG9kXCI6JHtodHRwSGVhZGVyLm1ldGhvZH0sXCJpcFwiOiR7Y2xpZW50SXB9LFwib2JqZWN0XCI6JHtvYmplY3R9LFwic3BcIjoke3g6c3B9LFwidG9rZW5cIjoke3g6dG9rZW59LFwidHRsXCI6JHt4OnR0bH0sXCJjbGllbnRfdG9rZW5cIjoke3F1ZXJ5U3RyaW5nLmNsaWVudF90b2tlbn19In0%3D&ud=16-0-6-0-8-N-4-N-1 -O com.YoStarJP.AzurLane -q
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
