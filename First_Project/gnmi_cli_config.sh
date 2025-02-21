declare -A PATH_TO_CLI=(
    ["/interfaces/interface[name=eth0]/state/counters"]="show interfaces eth0 counters"
    ["/system/memory/state"]="show memory"
    ["/interfaces/interface[name=eth1]/state/counters"]="show interfaces eth1 counters"
    ["/system/cpu/state/usage"]="show cpu"
    ["/routing/protocols/protocol[ospf]/ospf/state"]="show ospf status"
    ["/interfaces/interface[name=eth0]/state"]="show interfaces eth0 status; show interfaces eth0 mac-address; show interfaces eth0 mtu; show interfaces eth0 speed"
    ["/bgp/neighbors/neighbor[neighbor_address=10.0.0.1]/state"]="show bgp neighbors 10.0.0.1; show bgp neighbors 10.0.0.1 received-routes; show bgp neighbors 10.0.0.1 advertised-routes"
    ["/ospf/areas/area[id=0.0.0.0]/state"]="show ospf area 0.0.0.0; show ospf neighbors"
    ["/system/disk/state"]="show disk space; show disk health"
    ["/system/cpu/state"]="show cpu usage; show cpu user; show cpu system; show cpu idle"
)


declare -A GNMI_OUTPUTS=(
    ["/interfaces/interface[name=eth0]/state/counters"]='{"in_octets": 1500000, "out_octets": 1400000, "in_errors": 10, "out_errors": 2}'
    ["/system/memory/state"]='{"total_memory": 4096000, "available_memory": 1024000, "used": "361296bytes"}'
    ["/interfaces/interface[name=eth1]/state/counters"]='{"in_octets": 200000, "out_octets": 100000, "in_errors": 5}'
    ["/system/cpu/state/usage"]='{"cpu_usage": 65, "idle_percentage": 35}'
    ["/routing/protocols/protocol[ospf]/ospf/state"]='{"ospf_area": "0.0.0.0", "ospf_state": "up"}'
    ["/interfaces/interface[name=eth0]/state"]='{"admin_status": "ACTIVE", "oper_status": "LINK_UP", "mac_address": "00:1C:42:2B:60:5A", "mtu": 1500, "speed": 1000000000}'
    ["/bgp/neighbors/neighbor[neighbor_address=10.0.0.1]/state"]='{"peer_as": 65001, "connection_state": "Established", "received_prefix_count": 120, "sent_prefix_count": 95}'
    ["/ospf/areas/area[id=0.0.0.0]/state"]='{"area_id": "0.0.0.0", "active_interfaces": 4, "lsdb_entries": 200, "adjacencies": [{"neighbor_id": "1.1.1.1", "state": "full"}, {"neighbor_id": "2.2.2.2", "state": "full"}]}'
    ["/system/disk/state"]='{"total_space": 1024000, "used_space": 500000, "available_space": 524000, "disk_health": "good"}'
    ["/system/cpu/state"]='{"cpu_usage": 75, "user_usage": 45, "system_usage": 20, "idle_percentage": 25, "utilization": 31, "used": 43}'
)

declare -A CLI_OUTPUTS=(
    ["/interfaces/interface[name=eth0]/state/counters"]='in_octets: 1500000\nout_octets: 1400000\nin_errors: 10\nout_errors: 2'
    ["/system/memory/state"]='total_memory: 4096000\navailable_memory: 1024000\nused: 352.8289KB'
    ["/interfaces/interface[name=eth1]/state/counters"]='in_octets: 200000\nout_octets: 100000'
    ["/system/cpu/state/usage"]='cpu_usage: 65'
    ["/routing/protocols/protocol[ospf]/ospf/state"]='ospf_area: 0.0.0.0\nospf_state: down'
    ["/interfaces/interface[name=eth0]/state"]='admin_status: Active\noper_status: LinkUp\nmac_address: 10:1C:42:2B:60:5A\nmtu: 1500\nspeed: 1G'
    ["/bgp/neighbors/neighbor[neighbor_address=10.0.0.1]/state"]='peer_as: 65001\nconnection_state: Established\nreceived_prefix_count: 120\nsent_prefix_count: 95'
    ["/ospf/areas/area[id=0.0.0.0]/state"]=$'area_id: 0.0.0.0\nactive_interfaces: 4\nlsdb_entries: 200\nneighbor_id: 12.1.1.1, state: full\nneighbor_id: 2.2.2.2, state: full'
    ["/system/disk/state"]='total_space: 1024000\nused_space: 500000\navailable_space: 524000\ndisk_health: good'
    ["/system/cpu/state"]='cpu_usage: 75\nuser_usage: 45\nsystem_usage: 20\nidle_percentage: 25\nutilization: 31.0%\nused: 43.20'
)
