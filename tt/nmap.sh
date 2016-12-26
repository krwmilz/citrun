#!/bin/sh -u
#
# Instruments Nmap and checks that the instrumented program still runs.
#
. tt/package.subr "net/nmap"
plan 10

pkg_check_deps
pkg_clean
pkg_build
pkg_test

cat <<EOF > check.good
Summary:
       400 Source files used as input
        83 Application link commands
       334 Rewrite successes
        66 Rewrite failures
       311 Rewritten source compile successes
        23 Rewritten source compile failures

Totals:
    173596 Lines of source code
      3809 Function definitions
      8083 If statements
       876 For loops
       410 While loops
        58 Do while loops
       286 Switch statements
      4565 Return statement values
     17515 Call expressions
    298886 Total statements
     20625 Binary operators
       588 Errors rewriting source
EOF
pkg_check

cat <<EOF > tu_list.good
./fad-getad.c 281
./gencode.c 8905
./inet.c 1142
./nametoaddr.c 510
./optimize.c 2356
./pcap-bpf.c 2753
./pcap-common.c 1387
./pcap.c 2030
./savefile.c 417
./sf-pcap-ng.c 1275
./sf-pcap.c 895
ARPHeader.cc 378
DestOptsHeader.cc 160
EthernetHeader.cc 284
FragmentHeader.cc 277
HopByHopHeader.cc 452
ICMPv4Header.cc 1252
ICMPv6Header.cc 1423
IPv4Header.cc 699
IPv6Header.cc 570
PacketElement.cc 135
PacketParser.cc 1858
RawData.cc 237
RoutingHeader.cc 374
TCPHeader.cc 1001
Target.cc 578
TargetGroup.cc 819
TransportLayerElement.cc 190
UDPHeader.cc 363
addr-util.c 305
addr.c 493
arp-bsd.c 324
bpf_filter.c 760
daxpy.c 50
ddot.c 51
dnrm2.c 63
dscal.c 45
engine_kqueue.c 371
engine_poll.c 428
engine_select.c 394
eth-bsd.c 173
filespace.c 119
gh_heap.c 251
grammar.c 754
intf.c 1088
ip-util.c 218
ip6.c 77
main.cc 230
nbase_addrset.c 651
nbase_memalloc.c 179
nbase_misc.c 955
nbase_rnd.c 424
nbase_str.c 380
netutils.c 198
nse_binlib.cc 414
nse_bit.cc 75
nse_debug.cc 103
nse_dnet.cc 368
nse_fs.cc 313
nse_lpeg.cc 8
nse_main.cc 823
nse_nmaplib.cc 1027
nse_nsock.cc 1137
nse_openssl.cc 610
nse_pcrelib.cc 405
nse_ssl_cert.cc 612
nse_utility.cc 206
nsock_connect.c 561
nsock_core.c 1416
nsock_engines.c 160
nsock_event.c 543
nsock_iod.c 449
nsock_log.c 121
nsock_pcap.c 495
nsock_pool.c 311
nsock_proxy.c 460
nsock_read.c 135
nsock_ssl.c 186
nsock_timers.c 81
nsock_write.c 237
protocols.cc 252
proxy_http.c 215
proxy_socks4.c 246
route-bsd.c 693
scan_engine.cc 2753
scan_engine_connect.cc 564
scan_engine_raw.cc 2279
scanner.c 460
service_scan.cc 2818
services.cc 578
targets.cc 729
tcpip.cc 2172
timing.cc 780
traceroute.cc 1660
tron.cpp 236
utils.cc 721
xml.cc 463
EOF

$workdir/nmap > /dev/null

ok "is write_tus.pl exit code 0" \
	perl -I$treedir $treedir/tt/write_tus.pl ${CITRUN_PROCDIR}nmap_*

sort -o tu_list.out tu_list.out
ok "translation unit manifest" diff -u tu_list.good tu_list.out

pkg_clean
