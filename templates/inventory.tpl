[Ansi-cont]
%{ for ip in ansi_cont_pub ~}
${ip}
%{ endfor ~}

[Web]
%{ for index, ip in web_clients_pub ~}
web${index} ansible_host=${ip} private_ip=${web_clients_pri[index]}
%{ endfor ~}

[DB]
%{ for index, ip in db_clients_pub ~}
DB${index} ansible_host=${ip} private_ip=${db_clients_pri[index]}
%{ endfor ~}

