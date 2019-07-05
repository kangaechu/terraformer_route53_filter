#!/usr/bin/env bash -ex

if [[ $# != 2 ]]; then
    echo "mismatch parameter"
    exit 1
fi

ZONE_ID=$1
ZONE_NAME=$2
ZONE_NAME_UNDERSCORE=${ZONE_NAME//./_}

# terraformerの作業用ディレクトリを削除
rm -rf generated

# terraformのディレクトリを作成
cp -pr template ${ZONE_NAME}

ruby terraformer_filter.rb ${ZONE_ID}
terraformer import plan ${ZONE_ID}.json

# 変数部分を置換
find ${ZONE_NAME} -name "*.txt" -type f -print0 | xargs -0 sed -i '' -e "s/########/${ZONE_NAME}/"
find ${ZONE_NAME} -name "*.tf" -type f -print0 | xargs -0 sed -i '' -e "s/@@@@@@@@/${ZONE_NAME_UNDERSCORE}/"

# .tfをコピー
cat ${ZONE_NAME}/aws_route53_record_header.txt route53/route53_record.tf > ${ZONE_NAME}/aws_route53_record.tf
cp route53/route53_zone.tf ${ZONE_NAME}/aws_route53_zone.tf
# tfstateをコピー
cp route53/terraform.tfstate ${ZONE_NAME}/terraform.tfstate.generated

cd ${ZONE_NAME}/

eval "$(direnv export bash)"

rm aws_route53_record_header.txt

# aws_route53_zoneにcommentパラメータを追加
sed -i '' -e 's/^}$/comment=""\'$'\n}/' aws_route53_zone.tf
terraform fmt

terraform init
terraform 0.12upgrade
rm versions.tf
terraform state push terraform.tfstate.generated
rm terraform.tfstate.generated

terraform plan
cd ..

# ごみそうじ
rm ${ZONE_ID}.json
rm -rf route53
