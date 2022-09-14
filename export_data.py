# argument: directory with data. Will turn non-semicolon-separated files into separate semicolon-separated values
import sys


dir = sys.argv[1]
customers = dir + "/Customers.txt"
stations = dir + "/Stations.txt"
trains = dir + "/Trains.txt"
rail_lines = dir + "/RailLines.txt"
routes = dir + "/Routes.txt"
route_schedule = dir + "/RouteSched.txt"

def open_file_reads():
    file_reads = {}
    file_reads["customers"] = open(customers)
    file_reads["stations"] = open(stations)
    file_reads["trains"] = open(trains)
    file_reads["rail_lines"] = open(rail_lines)
    file_reads["routes"] = open(routes)
    file_reads["route_schedule"] = open(route_schedule)
    return file_reads

def close_file_dict(file_dict):
    for f in file_dict:
        file_dict[f].close()

def open_file_writes():
    file_writes = {}
    file_writes["Customer"] = open("Customer.dat", 'w')
    file_writes["Station"] = open("Station.dat", 'w')
    file_writes["Train"] = open("Train.dat", 'w')
    file_writes["Rail_Line"] = open("Rail_Line.dat", 'w')
    file_writes["Passes_Thru_SRL"] = open("Passes_Thru_SRL.dat", 'w')
    file_writes["Route"] = open("Route.dat", 'w')
    file_writes["Passes_Thru_SR"] = open("Passes_Thru_SR.dat", 'w')
    file_writes["Route_Schedule"] = open("Route_Schedule.dat", 'w')
    return file_writes

file_reads = open_file_reads()
file_writes = open_file_writes()

# Script code
for c_line in file_reads["customers"].readlines():
    file_writes["Customer"].write(c_line)

for s_line in file_reads["stations"].readlines():
    file_writes["Station"].write(s_line)

for t_line in file_reads["trains"].readlines():
    file_writes["Train"].write(t_line)

for rl_line in file_reads["rail_lines"].readlines():
    line_id = ""
    i = 9
    while rl_line[i] != " ":
        line_id += rl_line[i]
        i += 1
    speed_limit = ""
    i += 14
    while rl_line[i] != " ":
        speed_limit += rl_line[i]
        i += 1
    file_writes["Rail_Line"].write(line_id + ";" + speed_limit + "\n")
    i += 11
    info = [[], []]
    info_index = 0
    curr = ""
    while i < len(rl_line):
        if rl_line[i] == ",":
            info[info_index].append(curr)
            curr = ""
            i += 1
        elif rl_line[i] == " ":
            info[info_index].append(curr)
            curr = ""
            info_index += 1
            i += 11
        elif rl_line[i] != "\n":
            curr += rl_line[i]
        i += 1
    info[info_index].append(curr)
    for k in range(len(info[0])):
        file_writes["Passes_Thru_SRL"].write(line_id + ";" + info[0][k] + ";" + info[1][k] + "\n")

for r_line in file_reads["routes"].readlines():
    route_id = ""
    i = 7
    while r_line[i] != " ":
        route_id += r_line[i]
        i += 1
    file_writes["Route"].write(route_id + "\n")
    i += 12
    stations_dic = {}
    curr = ""
    while i < len(r_line):
        if r_line[i] == ",":
            stations_dic[curr] = False
            curr = ""
            i += 1
        elif r_line[i] == " ":
            stations_dic[curr] = False
            curr = ""
            i += 8
            break
        elif r_line[i] != "\n":
            curr += r_line[i]
        i += 1
    while i < len(r_line):
        if r_line[i] in [",", "\n"]:
            stations_dic[curr] = True
            curr = ""
            i += 1
        else:
            curr += r_line[i]
        i += 1
    for k, v in stations_dic.items():
        file_writes["Passes_Thru_SR"].write(route_id + ";" + k + ";" + str(v) + "\n")

for rs_line in file_reads["route_schedule"].readlines():
    file_writes["Route_Schedule"].write(rs_line)

close_file_dict(file_reads)
close_file_dict(file_writes)