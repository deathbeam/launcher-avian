set -e
PLATFORM=linux
ARCH=x86_64
SOURCE=true
CLEAN=true
TOP_LEVEL_DIR=$(pwd)

if [ $SOURCE = true ]; then
  AVIAN_BUILD_DIR=avian/build/$PLATFORM-$ARCH-openjdk-src
else
  AVIAN_BUILD_DIR=avian/build/$PLATFORM-$ARCH-openjdk
fi

if [ ! -d "avian" ]; then
	git clone https://github.com/ReadyTalk/avian.git
fi

export JAVA_HOME="$TOP_LEVEL_DIR/jdk"
cd $TOP_LEVEL_DIR/avian

if [ $CLEAN = true ]; then
  make clean
fi

if [ $SOURCE = true ]; then
  make platform=$PLATFORM \
    arch=$ARCH \
    openjdk="$JAVA_HOME" \
    openjdk-src="$TOP_LEVEL_DIR/jdk-src"
else
  make platform=$PLATFORM \
    arch=$ARCH \
    openjdk="$JAVA_HOME"
fi

cd $TOP_LEVEL_DIR
rm -rf build
mkdir build
cd build

ar x $TOP_LEVEL_DIR/$AVIAN_BUILD_DIR/libavian.a
cp $TOP_LEVEL_DIR/$AVIAN_BUILD_DIR/classpath.jar boot.jar

mkdir classes
(cd classes; jar -xf $TOP_LEVEL_DIR/client.jar)
(cd classes; jar u0f ../boot.jar .)

$TOP_LEVEL_DIR/$AVIAN_BUILD_DIR/binaryToObject/binaryToObject boot.jar \
     boot-jar.o _binary_boot_jar_start _binary_boot_jar_end $PLATFORM $ARCH

cp $TOP_LEVEL_DIR/launcher.cpp ./

g++ -I$JAVA_HOME/include -I$JAVA_HOME/include/linux -D_JNI_IMPLEMENTATION_ -c launcher.cpp -o main.o
g++ -rdynamic *.o -ldl -lpthread -lz -o launcher
