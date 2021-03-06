#!/bin/sh
sudo apt-get install \
  ruby \
  rake \
  pandoc \
  ruby-graphviz \
  xdot \
  git \
  default-jdk \
  inkscape \
  dpic
  
sudo -v && wget -nv -O- https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py | sudo python -c "import sys; main=lambda:sys.stderr.write('Download failed\n'); exec(sys.stdin.read()); main()"

# dpic -v ./diagram.pic > ./diagram.svg && inkscape -z -d 100 -e ./diagram.png ./diagram.svg && eog ./diagram.png
