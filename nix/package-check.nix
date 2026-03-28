{
  pkgs,
  piMentci,
  samskaraReaderMcp,
}:

pkgs.runCommand "pi-mentci-check" { } ''
  test -x ${piMentci}/bin/pi
  test -x ${piMentci}/bin/pi-mentci
  test -e ${piMentci}/lib/node_modules/pi/node_modules/@aliou/pi-linkup/src/index.ts
  test -e ${piMentci}/lib/node_modules/pi/node_modules/pi-interactive-shell/index.ts
  test -e ${piMentci}/lib/node_modules/pi/node_modules/pi-mcp-adapter/index.ts
  grep -q "node_modules/pi-mcp-adapter" ${piMentci}/bin/pi
  grep -q "node_modules/pi-interactive-shell" ${piMentci}/bin/pi
  grep -q "node_modules/@aliou/pi-linkup" ${piMentci}/bin/pi
  grep -q "${samskaraReaderMcp}/bin" ${piMentci}/bin/pi
  touch "$out"
''
