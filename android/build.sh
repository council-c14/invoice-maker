#!/usr/bin/env bash
# Builds invoice-maker.apk from public/index.html with the plain Android SDK tools (no Gradle).
# Needs: JDK 17+, ANDROID_HOME with platforms;android-36 and build-tools;36.0.0.
# Signing: KEYSTORE (path), KEYSTORE_PASS. Keep that keystore safe: updates must be signed with the same key.
set -euo pipefail
cd "$(dirname "$0")"
VERSION_CODE=${VERSION_CODE:-1}
VERSION_NAME=${VERSION_NAME:-1.0}
: "${ANDROID_HOME:?set ANDROID_HOME}" "${KEYSTORE:?set KEYSTORE}" "${KEYSTORE_PASS:?set KEYSTORE_PASS}"
BT=$ANDROID_HOME/build-tools/36.0.0
JAR=$ANDROID_HOME/platforms/android-36/android.jar

rm -rf build && mkdir -p build/gen build/classes build/assets
cp ../public/index.html build/assets/index.html

"$BT/aapt2" compile --dir res -o build/res.zip
"$BT/aapt2" link -I "$JAR" --manifest AndroidManifest.xml -A build/assets build/res.zip \
  --java build/gen --min-sdk-version 24 --target-sdk-version 36 \
  --version-code "$VERSION_CODE" --version-name "$VERSION_NAME" -o build/unsigned.apk
javac -Xlint:-options --release 11 -classpath "$JAR" -d build/classes $(find src build/gen -name '*.java')
"$BT/d8" --release --min-api 24 --lib "$JAR" --output build $(find build/classes -name '*.class')
(cd build && zip -q unsigned.apk classes.dex)
"$BT/zipalign" -f -p 4 build/unsigned.apk build/aligned.apk
"$BT/apksigner" sign --ks "$KEYSTORE" --ks-pass "pass:$KEYSTORE_PASS" --out build/invoice-maker.apk build/aligned.apk
"$BT/apksigner" verify build/invoice-maker.apk
echo "Built android/build/invoice-maker.apk"
