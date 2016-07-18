#!/bin/bash
# Create love file
cd $1; zip -9 -q -r $2.love .
mv $2 ../binaries
cd ../binaries

# Win32
cd win32
cat love.exe $2.love > $2.exe
cd ..
#Win64
cd win64
cat love.exe $2.love > $2.exe
cd ..
#Mac OS X
cp love.app $2.app
cp $2.love $2.app/Contents/Resources/
mate $2.app/Contents/Info.plist