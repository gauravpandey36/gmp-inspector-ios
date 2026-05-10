#!/bin/bash
echo "=== Generating Flutter iOS scaffold ==="
cd /tmp
flutter create scaffold --org com.gmpinspector --platforms ios,android --project-name gmp_inspector
cp -r /tmp/scaffold/ios/ $CM_BUILD_DIR/ios/ 2>/dev/null || cp -r /tmp/scaffold/ios/ $FCI_BUILD_DIR/ios/ 2>/dev/null || echo "Trying PWD..."
cp -r /tmp/scaffold/android/ $CM_BUILD_DIR/android/ 2>/dev/null || cp -r /tmp/scaffold/android/ $FCI_BUILD_DIR/android/ 2>/dev/null
# Fallback: copy to the clone directory
if [ ! -d "$CM_BUILD_DIR/ios" ]; then
  CLONE_DIR=$(pwd)
  cp -r /tmp/scaffold/ios/ "$CLONE_DIR/ios/"
  cp -r /tmp/scaffold/android/ "$CLONE_DIR/android/"
fi
echo "=== iOS scaffold generated ==="
ls -la ios/ 2>/dev/null || echo "ios/ not found in current dir"
