#!/usr/bin/env bash

crontab -r


if [ ${enable_52pojie} ];then
  echo "10 13 * * *       node ${ASM_DIR}/scripts/index.js 52pojie --htVD_2132_auth=${htVD_2132_auth} --htVD_2132_saltkey=${htVD_2132_saltkey}" >> /etc/crontabs/root
fi

if [ ${enable_bilibili} ];then
  echo "*/30 7-22 * * *       node ${ASM_DIR}/scripts/index.js bilibili --cookies ${cookies} --username ${username} --password ${password} ${othercfg}" >> /etc/crontabs/root
fi

if [ ${enable_iqiyi} ];then
  echo "*/30 7-22 * * *       node ${ASM_DIR}/scripts/index.js iqiyi --P00001 ${P00001} --P00PRU ${P00PRU} --QC005 ${QC005}  --dfp ${dfp}" >> /etc/crontabs/root
fi

if [ ${enable_unicom} ];then
  echo "*/30 7-22 * * *       node ${ASM_DIR}/scripts/index.js unicom" >> /etc/crontabs/root
fi

if [ ${enable_10086} ];then
  echo "10 13 * * *       node ${ASM_DIR}/scripts/index.js 10086 --cookies ${cookies}" >> /etc/crontabs/root
fi
 
# set to update repository on every 30mins
echo "*/30 * * * *    cd  ${ASM_DIR}/scripts && git fetch --all && git reset --hard origin/${ASM_SCRIPTS_BRANCH}" >> /etc/crontabs/root


/usr/sbin/crond -c /etc/crontabs -f

tail -f /var/log/cron.log