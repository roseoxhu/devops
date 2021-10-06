#!/bin/sh
#set -x

###########################################################
### 本脚本执行VUE项目开发/测试/生产环境代码构建部署操作：
###    域名替换，接口签名配置
### $1 构建环境 dev|test|prod
### $2 构建分支版本号@发布分支（主干）
###########################################################

# 构建参数
BUILD_ENV=$1
BUILD_NAME=adminvue
PROJECT_NAME=$BUILD_NAME
PROJECT_HOME=/data/repository/projects/${PROJECT_NAME}
SVN_REVISION=$2

if [[ $# < 1 ]]; then
    echo "Usage: $0 <BUILD_ENV> [SVN_REV]"
    exit 1
fi

# 服务器IP
SVN_SERVER='192.168.1.10'
DEV_HOST=192.168.1.3 # localhost
TEST_HOST=192.168.1.5
PROD_HOST=123.xxx.xxx.xxx
DEPLOY_USER=bazer

# 首次从主干手动拉取代码下来
# mkdir -p ~/projects/${PROJECT_NAME} && cd ~/projects/${PROJECT_NAME}
# svn checkout svn://${SVN_SERVER}/REPO_ROOT/${PROJECT_NAME}/trunk
# svn info
# svn --revision HEAD info ~/projects/${PROJECT_NAME}/trunk
PROJECT_SRC=${PROJECT_HOME}/trunk

# 当前日期
TODAY=`date +%Y%m%d`
WORKSPACE=${PROJECT_HOME}/workspace

echo "[$(date '+%F %T')] Start build ..."
if [[ ! -d ${PROJECT_SRC} ]]; then
    echo "[$(date '+%F %T')] Create folder $PROJECT_SRC"
    mkdir -p "$PROJECT_SRC"
fi

cd ${PROJECT_SRC}
SVN_INFO=`svn info ${PROJECT_SRC}`
# if [[ -z `ls -A ${PROJECT_SRC}` ]]; then
if [[ "$?" == "0" ]]; then
    # 从主干更新代码
    echo "[$(date '+%F %T')] svn update to $PROJECT_SRC"
    if [[ "${SVN_REVISION}" == "" ]]; then
        svn update # HEAD
    else
        svn --revision ${SVN_REVISION} update
    fi
else
    # 从主干检出代码
    echo "[$(date '+%F %T')] svn checkout to $PROJECT_SRC"
    if [[ "${SVN_REVISION}" == "" ]]; then
        svn checkout svn://${SVN_SERVER}/REPO_ROOT/${PROJECT_NAME}/trunk .
    else
        svn checkout svn://${SVN_SERVER}/REPO_ROOT/${PROJECT_NAME}/trunk@${SVN_REVISION} .
    fi
fi

if [[ "${SVN_REVISION}" == "" ]]; then
    # 获取发布分支（主干）最新版本号
    SVN_REVISION=`svn --revision HEAD info ${PROJECT_SRC} | awk 'NR==8{print $4}'`
    echo "[$(date '+%F %T')] Last changed rev: $SVN_REVISION"
fi

# 构建目录
MODULE_SRC=${WORKSPACE}/src
if [[ ! -d ${MODULE_SRC} ]]; then
    echo "[$(date '+%F %T')] Create folder $MODULE_SRC"
    mkdir -p "$MODULE_SRC"
fi

BUILD_TARGET=${WORKSPACE}/target
if [[ ! -d ${BUILD_TARGET} ]]; then
    echo "[$(date '+%F %T')] Create folder $BUILD_TARGET"
    mkdir -p "$BUILD_TARGET"
fi

echo "[$(date '+%F %T')] Clean up ${MODULE_SRC}"
echo "[$(date '+%F %T')] Rsync from ${PROJECT_HOME}/trunk to workspace/src"
# 如果使用-C, --cvs-exclude选项, 则Rsync将排除以下类型的文件：
#static char default_cvsignore[] =
#    /* These default ignored items come from the CVS manual. */
#    "RCS SCCS CVS CVS.adm RCSLOG cvslog.* tags TAGS"
#    " .make.state .nse_depinfo *~ #* .#* ,* _$* *$"
#    " *.old *.bak *.BAK *.orig *.rej .del-*"
#    " *.a *.olb *.o *.obj *.so *.exe"
#    " *.Z *.elc *.ln core"
#    /* The rest we added to suit ourself. */
#    " .svn/ .git/ .hg/ .bzr/";
# rsync -alq --cvs-exclude ${PROJECT_SRC}/ ${MODULE_SRC}/
rsync -alq --exclude=.svn/ --exclude=.git/ ${PROJECT_SRC}/ ${MODULE_SRC}/
echo "[$(date '+%F %T')] Rsync done"

# 测试环境 域名替换 dev.foobar.com -> test.foobar.com
if [[ "${BUILD_ENV}" == "test" ]]; then
    FR=dev.foobar.com
    TO=test.foobar.com
    echo "[$(date '+%F %T')] Replace '$FR' to '$TO'"
    sed -i "s/$FR/$TO/g" `grep "$FR" -rl ${MODULE_SRC}`
fi

# 生产环境 域名替换 dev.foobar.com -> foobar.com
if [[ "${BUILD_ENV}" == "prod" ]]; then
    FR=dev.foobar.com
    TO=foobar.com
    echo "[$(date '+%F %T')] Replace '$FR' to '$TO'"
    sed -i "s/$FR/$TO/g" `grep "$FR" -rl ${MODULE_SRC}`

    FR=test.foobar.com
    TO=foobar.com
    echo "[$(date '+%F %T')] Replace '$FR' to '$TO'"
    sed -i "s/$FR/$TO/g" `grep "$FR" -rl ${MODULE_SRC}`
fi

# 事先配置好 NodeJS 环境 /usr/lib/node_modules
# sudo npm install -g @vue/cli
# vue -V
echo "[$(date '+%F %T')] Node building ..."
cd ${MODULE_SRC}
# npm install

if [ -d ${MODULE_SRC} ]; then
    # 删除老的构建文件 
    rm -rf ${MODULE_SRC}/dist/*
    echo "[$(date '+%F %T')] Delete ${MODULE_SRC}/dist/*"
fi

if [[ "${BUILD_ENV}" == "dev" ]]; then
    # npm run sit
    npm run preview  # 开发
elif [[ "${BUILD_ENV}" == "test" ]]; then
    # npm run uat
    npm run test     # 测试
else
    # npm run build    # 线上
    npm run build:prod
fi

# 将替换处理的源文件目录压缩打包
BUILD_FILE="$BUILD_TARGET/$BUILD_NAME-$TODAY-r${SVN_REVISION}-${BUILD_ENV}.zip"
if [[ -e ${BUILD_FILE} ]]; then
    rm -f ${BUILD_FILE}
fi

echo "[$(date '+%F %T')] Change dir: ${MODULE_SRC}/dist/"
cd ${MODULE_SRC}/dist/
/bin/zip -r ${BUILD_FILE} -x="*/.svn/*" -x favicon.ico *
echo "[$(date '+%F %T')] Created file: $BUILD_FILE"
echo "[$(date '+%F %T')] Build done."


echo "[$(date '+%F %T')] 构建完成，开始部署前端"
DEPLOY_TARGET=/path/to/deploy/target
DEPLOY_TO=/path/to/nginx/html/${PROJECT_NAME}
if [[ ! -d ${DEPLOY_TO} ]]; then
    mkdir -p "$DEPLOY_TO"
fi

if [[ "${BUILD_ENV}" == "dev" ]]; then
    echo "[$(date '+%F %T')] 部署开发环境 ..."
    rm -fR ${DEPLOY_TO}/*

    /bin/unzip -o ${BUILD_FILE} -d ${DEPLOY_TO}/
elif [[ "${BUILD_ENV}" == "test" ]]; then
    echo "[$(date '+%F %T')] 部署测试环境 ..."
    # 必须以 $DEPLOY_USER 用户执行此脚本
    echo "[$(date '+%F %T')] 同步压缩文件到测试服务器 $TEST_HOST:$DEPLOY_TARGET/"
    rsync -alv ${BUILD_FILE} $DEPLOY_USER@${TEST_HOST}:${DEPLOY_TARGET}/

    echo "[$(date '+%F %T')] 解压缩文件到部署目录 ${DEPLOY_TO}/"
    # ssh $DEPLOY_USER@$TEST_HOST > /dev/null 2>&1 << EOF
    # HERE-DOCUMENT end-of-file
    # "-o" overwrite files WITHOUT prompting
    ssh $DEPLOY_USER@$TEST_HOST << EOF
    rm -fR ${DEPLOY_TO}/*
    /bin/unzip -o ${DEPLOY_TARGET}/$(basename ${BUILD_FILE}) -d ${DEPLOY_TO}/
    exit
EOF
else
    echo "[$(date '+%F %T')] 部署生产环境 ...(手动)"
    echo "[$(date '+%F %T')] 同步压缩文件到生产服务器 $PROD_HOST:$DEPLOY_TARGET/"
    echo "rsync -alv ${BUILD_FILE} $DEPLOY_USER@${PROD_HOST}:${DEPLOY_TARGET}/"

    echo "[$(date '+%F %T')] 解压缩文件到部署目录 ${DEPLOY_TO}/"
    echo "rm -fR ${DEPLOY_TO}/*"
    echo "/bin/unzip -o ${DEPLOY_TARGET}/$(basename ${BUILD_FILE}) -d ${DEPLOY_TO}/"
fi

echo "[$(date '+%F %T')] 部署完成"
