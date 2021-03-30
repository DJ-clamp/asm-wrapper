#!/bin/sh
set -e

#获取配置的自定义参数，
if [ $1 ]; then
	run_cmd=$1
fi

if [[ -n "$run_cmd" && -n "$notify_tele_bottoken" && -n "$notify_tele_chatid" && -z "$DISABLE_BOT_COMMAND" ]]; then
  ENABLE_BOT_COMMAND=True
else
  ENABLE_BOT_COMMAND=False
fi

echo "git 拉取 asm-wrapper 最新代码..."
cd ${ASM_DIR}/docker
git fetch --all
git reset --hard HEAD
git pull origin main

echo "------------------------------------------------执行定时任务任务shell脚本------------------------------------------------"
#因为entrypoint.sh做为入口文件打包到镜像里面的更新调整不太方便，它的作用只是来更新我需要真正执行操作的default_task.sh
#把安装依赖包生成定时任务操作等放到default_task.sh，这样如果有调整去修改default_task.sh就可以，不需要更新打包镜像了
sh ${ASM_DIR}/docker/default_task.sh $ENABLE_BOT_COMMAND
echo "--------------------------------------------------默认定时任务执行完成---------------------------------------------------"

#这个判断是为了把entrypoint.sh这个入口文件利用起来如果有参数说明是容器启动需要crond -f启动hold住进程防止容器没人进行中任务退出
#如果容器运行过程中执行entrypoint.sh直接跳过就行了
if [ $run_cmd ]; then
  # 增加一层asm_bot指令已经正确安装成功校验
  # 以上条件都满足后会启动jd_bot交互，否还是按照以前的模式启动，最大程度避免现有用户改动调整
  if [[ "$ENABLE_BOT_COMMAND" == "True" && -f /usr/bin/asm_bot ]]; then
    echo "启动crontab定时任务主进程..."
    crond
    echo "启动telegram bot指令交主进程..."
    asm_bot
  else
    echo "启动crontab定时任务主进程..."
    crond -f
  fi

else
  echo "默认定时任务执行结束。"
fi