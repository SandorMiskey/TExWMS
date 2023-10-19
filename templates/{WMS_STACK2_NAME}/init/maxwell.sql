CREATE USER '${WMS_STACK4_S1_USER}'@'%' IDENTIFIED BY '${WMS_STACK4_S1_PW}';
CREATE USER '${WMS_STACK4_S1_USER}'@'localhost' IDENTIFIED BY '${WMS_STACK4_S1_PW}';

GRANT ALL ON maxwell.* TO '${WMS_STACK4_S1_USER}'@'%';
GRANT ALL ON maxwell.* TO '${WMS_STACK4_S1_USER}'@'localhost';

GRANT SELECT, REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO '${WMS_STACK4_S1_USER}'@'%';
GRANT SELECT, REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO '${WMS_STACK4_S1_USER}'@'localhost';