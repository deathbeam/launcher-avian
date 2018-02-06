PLATFORM=linux
ARCH=x86_64
TAILS=true
TOP_LEVEL_DIR=$(pwd)
AVIAN_BUILD_DIR=avian/build/$PLATFORM-$ARCH

if [ $TAILS ]; then
	AVIAN_BUILD_DIR=avian/build/$PLATFORM-$ARCH-tails
fi

if [ ! -d "avian" ]; then
	git clone https://github.com/ReadyTalk/avian.git
	git reset --hard edbce08
fi

export JAVA_HOME=$(/usr/lib/jvm/java-8-openjdk)
cd $TOP_LEVEL_DIR/avian
make platform=$PLATFORM tails=$TAILS

cd $TOP_LEVEL_DIR
mkdir build
cd build

ar x $TOP_LEVEL_DIR/$AVIAN_BUILD_DIR/libavian.a
cp $TOP_LEVEL_DIR/$AVIAN_BUILD_DIR/classpath.jar boot.jar
cp $TOP_LEVEL_DIR/client.jar client.jar

mkdir classes
(cd classes; jar -xf ../client.jar)
(cd classes; jar -xf ../boot.jar)
jar -cvf combined.jar -C classes .

$TOP_LEVEL_DIR/$AVIAN_BUILD_DIR/binaryToObject/binaryToObject combined.jar \
     boot-jar.o _binary_boot_jar_start _binary_boot_jar_end $PLATFORM $ARCH

cp $TOP_LEVEL_DIR/launcher.cpp ./

g++ -I$JAVA_HOME/include -I$JAVA_HOME/include/linux -D_JNI_IMPLEMENTATION_ -c launcher.cpp -o main.o
g++ -rdynamic *.o -ldl -lpthread -lz -o launcher
strip --strip-all launcher
