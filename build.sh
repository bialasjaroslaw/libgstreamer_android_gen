if [ "$#" -ne 1 ]; then
  echo "Usage: $0 GSTREAMER_VERSION" >&2
  exit 1
fi

if [[ -z "${GSTREAMER_ROOT_ANDROID}" ]]; then
  echo "You must define an environment variable called GSTREAMER_ROOT_ANDROID and point it to the folder where you extracted the GStreamer binaries"
  exit 1
fi

if [[ -z "${NDK_DIR}" ]]; then
  echo "You must define an environment variable called NDK_DIR and point it to the folder where you keep android ndk"
  exit 1
fi

VERSION=$1
DATE=`date "+%Y%m%d-%H%M%S"`

rm -rf out
mkdir out
# arm armv7 x86 x86_64 arm64
for TARGET in armv7 x86_64 arm64 x86
do
  if [[ ! -d "${GSTREAMER_ROOT_ANDROID}/${TARGET}" ]]; then
      echo "\n\n=== Building GStreamer ${VERSION} for target ${TARGET} not possible as GStreamer does not have prebuild binaries for this target. ==="
      continue
  fi
  NDK_APPLICATION_MK="jni/${TARGET}.mk"
  echo "\n\n=== Building GStreamer ${VERSION} for target ${TARGET} with ${NDK_APPLICATION_MK} ==="

  ${NDK_DIR}/ndk-build NDK_APPLICATION_MK=$NDK_APPLICATION_MK V=1 APP_STRIP_MODE=--strip-unneeded

  if [ $TARGET = "armv7" ]; then
    LIB="armeabi-v7a"
  elif [ $TARGET = "arm" ]; then
    LIB="armeabi"
  elif [ $TARGET = "arm64" ]; then
    LIB="arm64-v8a"
  elif [ $TARGET = "x86_64" ]; then
    LIB="x86_64"
  else
    LIB="x86"
  fi;

  GST_LIB="gst-build-${LIB}"

  cp -r libs/${LIB}/libgstreamer_android.so ${GST_LIB}
  cp -r $GSTREAMER_ROOT_ANDROID/${TARGET}/lib/pkgconfig ${GST_LIB}

  echo 'Processing '$GST_LIB
  cd $GST_LIB
  sed -i -e 's?libdir=.*?libdir='`pwd`'?g' pkgconfig/*
  sed -i -e 's?.* -L${.*?Libs: -L${libdir} -lgstreamer_android?g' pkgconfig/*
  sed -i -e 's?Libs:.*?Libs: -L${libdir} -lgstreamer_android?g' pkgconfig/*
  sed -i -e 's?Libs.private.*?Libs.private: -lgstreamer_android?g' pkgconfig/*
  rm -rf pkgconfig/*pc-e*
  cd ..
  ZIP="gstreamer-${LIB}-${VERSION}-${DATE}"
  zip -v out/$ZIP.zip $GST_LIB/* -r
  zip -v out/$GST_LIB.zip $GST_LIB/* -r
  rm -rf $GST_LIB
done

rm -rf libs obj

zip -v out/src.zip src -r
rm -rf src

echo "\n*** Done ***\n`ls out`"
