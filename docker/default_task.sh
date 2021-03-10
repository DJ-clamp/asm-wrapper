#!/bin/sh
set -e

#获取配置的自定义参数，
if [ $1 ]; then
  #如果$1有值说明是容器启动调用的 执行配置系统以来包安装和id_rsa配置以及clone仓库的操作
  apk --no-cache add -f coreutils moreutils nodejs npm wget curl nano perl openssl openssh-client libav-tools libjpeg-turbo-dev libpng-dev libtool libgomp tesseract-ocr graphicsmagick
  npm config set registry https://registry.npm.taobao.org
  echo "配置仓库更新密钥..."
  mkdir -p /root/.ssh
  echo -e ${KEY} >/root/.ssh/id_rsa
  chmod 600 /root/.ssh/id_rsa
  ssh-keyscan github.com >/root/.ssh/known_hosts
  echo "容器启动，拉取脚本仓库代码..."
  if [ -f "${ASM_DIR}/scripts/AutoSignMachine.js" ]; then
    echo "仓库已经存在，跳过clone操作..."
  else
    if [  -d ${ASM_DIR}/tmp ];then
      rmdir ${ASM_DIR}/tmp
    fi
    git clone --no-checkout -b ${ASM_SCRIPTS_BRANCH} ${REPO_URL} ${ASM_DIR}/tmp
    mv ${ASM_DIR}/tmp/.git ${ASM_DIR}/scripts
    rmdir ${ASM_DIR}/tmp
  fi
fi
echo -e "--------------------------------------------------------------\n"
[ -f ${ASM_DIR}/scripts/package.json ] && PackageListOld=$(cat ${ASM_DIR}/scripts/package.json)
echo "git pull拉取最新代码..."
cd ${ASM_DIR}/scripts
git reset --hard HEAD
git fetch --all
git reset --hard origin/${ASM_SCRIPTS_BRANCH}

echo "npm install 安装最新依赖"
if [ ! -d ${ScriptsDir}/node_modules ]; then
    echo -e "检测到首次部署, 运行 npm install...\n"
    npm install -s --prefix ${ASM_DIR}/scripts >/dev/null
else
  if [[ "${PackageListOld}" != "$(cat package.json)" ]]; then
    echo -e "检测到package.json有变化，运行 npm install...\n"
    npm install -s --prefix ${ASM_DIR}/scripts >/dev/null
  else
    echo -e "检测到package.json无变化，跳过...\n"
  fi
fi


mergedListFile="${ASM_DIR}/config/merged_list_file.sh"
envFile="/root/.AutoSignMachine/.env"
echo "定时任务文件路径为 ${mergedListFile}"
echo '' >${mergedListFile}

if [ $ENABLE_52POJIE ]; then
  echo "10 13 * * * sleep \$((RANDOM % 120)); node ${ASM_DIR}/scripts/index.js 52pojie --htVD_2132_auth=${htVD_2132_auth} --htVD_2132_saltkey=${htVD_2132_saltkey} >> ${ASM_DIR}/logs/52pojie.log 2>&1 &" >>${mergedListFile}
else
  echo "未配置启用52pojie签到任务环境变量ENABLE_52POJIE，故不添加52pojie定时任务..."
fi

if [ $ENABLE_BILIBILI ]; then
  echo "*/30 7-22 * * * sleep \$((RANDOM % 120)); node ${ASM_DIR}/scripts/index.js bilibili --username ${BILIBILI_ACCOUNT} --password ${BILIBILI_PWD} >> ${ASM_DIR}/logs/bilibili.log 2>&1 &" >>${mergedListFile}
else
  echo "未配置启用bilibi签到任务环境变量ENABLE_BILIBILI，故不添加Bilibili定时任务..."
fi

if [ $ENABLE_IQIYI ]; then
  echo "*/30 7-22 * * * sleep \$((RANDOM % 120)); node ${ASM_DIR}/scripts/index.js iqiyi --P00001 ${P00001} --P00PRU ${P00PRU} --QC005 ${QC005}  --dfp ${dfp} >> ${ASM_DIR}/logs/iqiyi.log 2>&1 &" >>${mergedListFile}
else
  echo "未配置启用iqiyi签到任务环境变量ENABLE_IQIYI，故不添加iqiyi定时任务..."
fi

if [ $ENABLE_UNICOM ]; then
  if [ -f $envFile ]; then
    cp -f $envFile ${ASM_DIR}/scripts/config/.env
    if [ $UNICOM_JOB_CONFIG ]; then
      echo "找到联通细分任务配置故拆分，针对每个任务增加定时任务"
      minute=0
      hour=8
      job_interval=6
      for job in $(paste -d" " -s - <$UNICOM_JOB_CONFIG); do
        echo "$minute $hour * * * node ${ASM_DIR}/scripts/index.js unicom --tryrun --tasks $job >>${ASM_DIR}/logs/unicom_$job.log 2>&1 &" >>${mergedListFile}
        minute=$(expr $minute + $job_interval)
        if [ $minute -ge 60 ]; then
          minute=0
          hour=$(expr $hour + 1)
        fi
      done
    else
      # echo "*/30 7-22 * * * sleep \$((RANDOM % 120)); node ${ASM_DIR}/scripts/index.js unicom >> ${ASM_DIR}/logs/unicom.log 2>&1 &" >>${mergedListFile}
      echo "*/30 7-22 * * * sleep \$((RANDOM % 120)); node ${ASM_DIR}/scripts/index.js unicom | tee  ${ASM_DIR}/logs/unicom.log" >>${mergedListFile}
    fi
  else
    echo "未找到 .env配置文件，故不添加unicom定时任务。"
  fi
else
  echo "未配置启用unicom签到任务环境变量ENABLE_UNICOM，故不添加unicom定时任务..."
fi

echo "增加默认脚本更新任务..."
echo "21 */1 * * * entrypoint_less.sh >> ${ASM_DIR}/logs/default_task.log 2>&1" >>$mergedListFile

echo "增加 |ts 任务日志输出时间戳..."
sed -i "/\( ts\| |ts\|| ts\)/!s/>>/\|ts >>/g" $mergedListFile

echo "加载最新的定时任务文件..."
crontab $mergedListFile
