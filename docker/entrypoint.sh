#!/usr/bin/env bash
set -e

echo "设定远程仓库地址..."
mkdir -p /root/.ssh  && echo -e ${KEY} > /root/.ssh/id_rsa  && chmod 600 /root/.ssh/id_rsa  && ssh-keyscan github.com > /root/.ssh/known_hosts
cd ${ASM_DIR}/scripts
if [  -d ${ASM_DIR}/tmp ];then
  rm -rf ${ASM_DIR}/tmp
fi
git clone --no-checkout -b ${ASM_SCRIPTS_BRANCH} ${REPO_URL} ${ASM_DIR}/tmp
mv ${ASM_DIR}/tmp/.git ${ASM_DIR}/scripts
rm -rf ${ASM_DIR}/tmp
git reset --hard HEAD
echo "git pull拉取最新代码..."
cd  ${ASM_DIR}/scripts && git fetch --all && git reset --hard origin/${ASM_SCRIPTS_BRANCH}
echo "npm install 安装最新依赖"
npm config set registry https://registry.npm.taobao.org 
npm install -s --prefix ${ASM_DIR}/scripts >/dev/null
echo "------------------------------------------------执行定时任务任务shell脚本------------------------------------------------"
crontab -r
if [ ${enable_52pojie} ];then
  echo "10 13 * * *       node ${ASM_DIR}/scripts/index.js 52pojie --htVD_2132_auth=${htVD_2132_auth} --htVD_2132_saltkey=${htVD_2132_saltkey}" >> /etc/crontabs/root
fi

if [ ${enable_bilibili} ];then
  echo "*/30 7-22 * * *   node ${ASM_DIR}/scripts/index.js bilibili --cookies ${cookies} --username ${username} --password ${password} ${othercfg}" >> /etc/crontabs/root
fi

if [ ${enable_iqiyi} ];then
  echo "*/30 7-22 * * *   node ${ASM_DIR}/scripts/index.js iqiyi --P00001 ${P00001} --P00PRU ${P00PRU} --QC005 ${QC005}  --dfp ${dfp}" >> /etc/crontabs/root
fi

if [ ${enable_unicom} ];then
  echo "*/30 7-22 * * *   cd  ${ASM_DIR}/scripts && node ${ASM_DIR}/scripts/index.js unicom" >> /etc/crontabs/root
fi

if [ ${enable_10086} ];then
  echo "10 13 * * *       node ${ASM_DIR}/scripts/index.js 10086 --cookies ${cookies}" >> /etc/crontabs/root
fi
 
# set to update repository on every 30mins
echo "*/30 * * * *    cd  ${ASM_DIR} && git fetch --all && git reset --hard origin && cp -f ${ASM_DIR}/docker/entrypoint.sh /entrypoint.sh && chmod 777 /entrypoint.sh"  >> /etc/crontabs/root

echo "*/30 * * * *    cd  ${ASM_DIR}/scripts && git fetch --all && git reset --hard origin/${ASM_SCRIPTS_BRANCH}" >> /etc/crontabs/root


/usr/sbin/crond -c /etc/crontabs -f

tail -f /var/log/cron.log