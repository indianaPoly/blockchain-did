#!/bin/bash

# ===============================
# 사용자 이름 및 학번 입력
# ===============================
NAME=$1
STD_ID=$2

if [ -z "$NAME" ] || [ -z "$STD_ID" ]; then
    echo "사용법: ./register_user.sh <NAME> <Student ID>"
    exit 1
fi

# ===============================
# 환경 설정
# ===============================
ORG_NAME=org1
ORG_DOMAIN=org1.example.com
CA_PORT=7054
CA_HOST=localhost
CA_TLS_CERT=${PWD}/organizations/fabric-ca/${ORG_NAME}/tls-cert.pem

# fabric-ca-client 실행 가능하도록 bin 경로 추가
export PATH=$PATH:${PWD}/../bin

# 관리자 환경으로 사용자 등록 수행
export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/${ORG_DOMAIN}/

echo "[1] 사용자 등록 중..."

fabric-ca-client register \
    --id.name ${NAME} \
    --id.secret ${NAME}pw \
    --id.type client \
    --tls.certfiles ${CA_TLS_CERT}

# ===============================
# 사용자 인증서 발급
# ===============================
echo "[2] 인증서 발급 (Enroll) 중..."

USER_DIR=${PWD}/organizations/peerOrganizations/${ORG_DOMAIN}/users/${NAME}@${ORG_DOMAIN}
mkdir -p ${USER_DIR}
export FABRIC_CA_CLIENT_HOME=${USER_DIR}

fabric-ca-client enroll \
    --url https://${NAME}:${NAME}pw@${CA_HOST}:${CA_PORT} \
    --tls.certfiles ${CA_TLS_CERT}

# ===============================
# DID 생성
# ===============================
echo "[3] DID 생성 중..."

PUBLIC_KEY=${USER_DIR}/msp/signcerts/cert.pem

# 공개키에서 SHA256 해시로 DID 생성
DID_HASH=$(openssl x509 -in ${PUBLIC_KEY} -noout -pubkey | openssl dgst -sha256 | awk '{print $2}')
DID="did:fabric:${ORG_NAME}:${DID_HASH}"

# ===============================
# 출력 및 결과 저장
# ===============================
echo ""
echo "✅ 등록 완료!"
echo "이름: $NAME"
echo "학번: $STD_ID"
echo "DID: $DID"
echo ""

# JSON 저장
cat <<EOF > ${USER_DIR}/user_info.json
{
  "name": "$NAME",
  "student_id": "$STD_ID",
  "did": "$DID"
}
EOF

echo "📁 저장 완료: ${USER_DIR}/user_info.json"
