# javaee-dart
Simple Java EE application built with Wildfly Swarm and Google Dart

## Building client

1. Download Dart SDK from http://dartlang.org.
2. In directory client run command pub get.
3. In directory clietn run command pub build.
4. Copy generated files from directory client/build/web to server/tree-server/tree.endpoint/src/main/webapp .

## Building server

1. Download Maven and JDK8.
2. In directory server/tree-server/ run command mvn clean install.


## Running app

1. Run server app with command java -jar server/tree-server/tree.endpoint/target/tree.endpoint-1.0.0-swarm.jar.
2. In browser open url http://localhost:9080/ .
