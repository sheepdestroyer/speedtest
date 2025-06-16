# An aria2c based speedtest

This shell speed test will benchmark 8Gbps internet connections.
It will :

- Be based around the following aria2c commmand options :  
`aria2c --min-split-size=1M --max-concurrent-downloads=16 --split=16 --max-connection-per-server=16 --dir=/dev --out=null --quiet=true $(TEST_URL_BIG_FILE)`

- Download directly to `/dev/null` so storage is not a bottleneck

- Be threaded, so it can launch this command simultaneously for as many test URLs provided in test-servers-list.txt, for instance :
```
http://appliwave.testdebit.info/1G.iso
http://speedtest.milkywan.fr/files/1G.iso
http://scaleway.testdebit.info/1G.iso
```

- Use the most modern and efficient shell libraries available on Fedora 42

- Log to ./debug.log

- Graph real time stats refresh at 10 fps

- Display realtime bandwidth values in both Gbps and in MBps.
 
- Have a cmdline option should activate looping : re-starting individual downloads when they end
