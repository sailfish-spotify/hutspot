#include "spconnect.h"

#include <openssl/aes.h>
#include <openssl/evp.h>
#include <openssl/rand.h>

#include <QCryptographicHash>
#include <QDebug>
#include <QUrlQuery>

#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

#define REMOTE_NAME "Hutspot AuthBlob Capturer"

DH * get_dh();
void powm(BIGNUM * base, BIGNUM * exp, BIGNUM * modulus, BIGNUM * result) ;
void decrypt(const char * cipherName,
             unsigned char * ciphertext,
             int ciphertext_len,
             unsigned char * key,
             unsigned char * iv,
             QByteArray ** result);
void add_blob_length(QByteArray * ba, int length);
unsigned int read_blob_int(QByteArray &blob, unsigned int * pos);
void read_blob_bytes(QByteArray &blob, unsigned int * pos, QByteArray &data);

SPConnect::SPConnect(QObject *parent) : QObject(parent) {
    mdnsService = nullptr;

    // setup dh keys
    dh = get_dh();
    if(1 != DH_generate_key(dh)) {
        qDebug() << "Failed to generate DH key pair";
        return;
    }

    // Librespot uses 95 byte keys, openssl generated a 96 byte one
    // so reduce by one byte
    BN_rshift(dh->priv_key, dh->priv_key, 8);

    // generate public key
    powm(dh->g, dh->priv_key, dh->p, dh->pub_key);

    int publicKeyLength = BN_num_bytes(dh->pub_key);
    unsigned char * publicKeyBytes = (unsigned char *)malloc(publicKeyLength);
    BN_bn2bin(dh->pub_key, publicKeyBytes);
    QByteArray publicKey = QByteArray((const char*)publicKeyBytes, publicKeyLength);
    publicKey64 = publicKey.toBase64();
    //qDebug() << "publicKey: " << publicKey64;
    free(publicKeyBytes);

    deviceId64 = getDeviceId(REMOTE_NAME);
}

QString SPConnect::getDeviceId(QString deviceName) {
    return QString(QCryptographicHash::hash(deviceName.toUtf8(), QCryptographicHash::Sha1).toHex());
}

void SPConnect::setCredentials(QString userName, int authType, QString authData) {

    // store auth data
    cred_auth_user_name = userName;
    cred_auth_type = authType;
    cred_auth_data =  QByteArray::fromBase64(authData.toUtf8());
    qDebug() << "user name: " << userName;
    qDebug() << "auth_type: " << authType;
    qDebug() << "auth_data: " << authData;
}

QString SPConnect::createBlobToSend(QString deviceName, QString clientKey) {
    int i, len;

    qDebug() << "createBlobToSend device name: " << deviceName;

    // create encrypted blob

    // create secret key
    QByteArray device_id = QCryptographicHash::hash(deviceName.toUtf8(), QCryptographicHash::Sha1).toHex();
    qDebug() << "device_id: " << device_id;
    QByteArray secret_key = QCryptographicHash::hash(device_id, QCryptographicHash::Sha1);
    //qDebug() << "secret: " << secret_key.toBase64();
    unsigned char pbkdf2_out[20];
    PKCS5_PBKDF2_HMAC_SHA1(secret_key.data(),
                           secret_key.length(),
                           (const unsigned char *)cred_auth_user_name.toUtf8().data(),
                           cred_auth_user_name.length(),
                           0x100,
                           20,
                           pbkdf2_out);
    secret_key = QCryptographicHash::hash(QByteArray((const char*)pbkdf2_out, 20), QCryptographicHash::Sha1);
    secret_key.append('\0'); secret_key.append('\0'); secret_key.append('\0'); secret_key.append(0x14);
    //qDebug() << "secret_key: " << secret_key.toBase64();

    // assemble blob
    QByteArray blob;
    blob.append(0x49);
    add_blob_length(&blob, cred_auth_user_name.length());
    blob.append(cred_auth_user_name);
    blob.append(0x50);
    blob.append(cred_auth_type); // assume < 128
    blob.append(0x51);
    add_blob_length(&blob, cred_auth_data.length());
    blob.append(cred_auth_data);
    blob.append(0x01);
    //qDebug() << "blob: " << blob.toBase64();

    // some xor magic
    len = blob.length();
    unsigned char xor_blob[len];
    memcpy(xor_blob, blob.constData(), len);
    for(i=0;i<len-0x10;i++)
        xor_blob[i+0x10]
            ^= xor_blob[i];
    QByteArray xored((const char*)xor_blob, len);
    //qDebug() << "  xored: " << xored.toBase64();

    // encrypt blob AES ecb 192 blob
    AES_KEY aes_key;
    if(AES_set_encrypt_key((const unsigned char *)secret_key.constData(), 192, &aes_key) < 0)
        qDebug() << "error setting AES encryption key";
    unsigned char encrypted_blob[len];
    for(i=0;i<len;i+=16)
        AES_ecb_encrypt((const unsigned char *)xor_blob+i,
                         encrypted_blob+i,
                         &aes_key,
                         AES_ENCRYPT);
    QByteArray eblob = QByteArray((const char*)encrypted_blob, len);

    // base64 encode it
    encrypted_blob64 = eblob.toBase64();
    qDebug() << "encrypted_blob: " << encrypted_blob64;

    // create shared_key
    BIGNUM * clientKeyBN;
    BIGNUM * sharedKeyBN = BN_new();
    QByteArray decClientKey = QByteArray::fromBase64(clientKey.toUtf8());
    clientKeyBN = BN_bin2bn((unsigned char *)decClientKey.data(), decClientKey.length(), nullptr);
    powm(clientKeyBN, dh->priv_key, dh->p, sharedKeyBN);
    unsigned char * sharedKeyBytes = (unsigned char *)malloc(BN_num_bytes(sharedKeyBN));
    BN_bn2bin(sharedKeyBN, sharedKeyBytes);
    QByteArray sharedKey = QByteArray((const char*)sharedKeyBytes, BN_num_bytes(sharedKeyBN));
    //qDebug() << "client_key: " << clientKey;
    //qDebug() << "sharedKey: " << sharedKey.toBase64();

    // create encryption keys and checks
    QByteArray key = QCryptographicHash::hash(sharedKey, QCryptographicHash::Sha1);
    QByteArray base_key = key.left(16);
    //qDebug() << "base_key: " << base_key.toBase64();
    QByteArray checksum_key = hmacSha1(base_key, "checksum");
    //qDebug() << "checksum_key: " << checksum_key.toBase64();
    QByteArray encryption_key = hmacSha1(base_key, "encryption");
    //qDebug() << "encryption_key: " << encryption_key.toBase64();
    encryption_key = encryption_key.left(16);

    // encrypt AES_ctr128

    // create initial vector and add it to blob data
    unsigned char iv[16];
    RAND_bytes(iv, 0x10);
    QByteArray ivArray((const char*)iv, 16);
    qDebug() << "  iv: " << ivArray.toBase64();
    QByteArray blob_to_send = QByteArray((const char *)iv, sizeof(iv));

    if(AES_set_encrypt_key((const unsigned char *)encryption_key.data(), 128, &aes_key) < 0)
        qDebug() << "error setting AES encryption key";
    unsigned int num = 0;
    unsigned char ecount[16];
    memset(ecount,0,sizeof(ecount));
    len = encrypted_blob64.length();
    unsigned char * encrypted_part = new unsigned char[len];
    AES_ctr128_encrypt((const unsigned char *)encrypted_blob64.data(),
                        encrypted_part,
                        len,
                        &aes_key,
                        iv,
                        ecount,
                        &num);
    QByteArray encrypted_blob_part  = QByteArray((const char*)encrypted_part, len);
    //qDebug() << "  encrypted_blob_part: " << encrypted_blob_part.toBase64();

    QByteArray checksum = hmacSha1(checksum_key, encrypted_blob_part);
    //qDebug() << "checksum: " << checksum.toBase64();

    // add encrypted part and checksum to the blob
    blob_to_send.append(encrypted_blob_part);
    blob_to_send.append(checksum);
    qDebug() << "blob_to_send: " << blob_to_send.toBase64();

    // base64 encode it
    return blob_to_send.toBase64();
}

QString SPConnect::getPublicKey() {
    return publicKey64;
}

void powm(BIGNUM * base, BIGNUM * exp, BIGNUM * modulus, BIGNUM * result) {
    BN_CTX * ctx = BN_CTX_new();
    BIGNUM * mbase = BN_dup(base);
    BIGNUM * mexp = BN_dup(exp);
    BN_one(result);

    while(!BN_is_zero(mexp)) {
        if(BN_is_odd(mexp)) {
            BN_mod_mul(result, result, mbase, modulus, ctx);
        }
        BN_rshift1(mexp, mexp);
        BN_mod_mul(mbase, mbase, mbase, modulus, ctx);
    }

    BN_free(mbase);
    BN_free(mexp);
    BN_CTX_free(ctx);
}

QByteArray SPConnect::hmacSha1(QByteArray key, QByteArray baseString) {
    int blockSize = 64; // HMAC-SHA-1 block size, defined in SHA-1 standard
    if (key.length() > blockSize) { // if key is longer than block size (64), reduce key length with SHA-1 compression
        key = QCryptographicHash::hash(key, QCryptographicHash::Sha1);
    }

    QByteArray innerPadding(blockSize, char(0x36)); // initialize inner padding with char "6"
    QByteArray outerPadding(blockSize, char(0x5c)); // initialize outer padding with char "quot;
    // ascii characters 0x36 ("6") and 0x5c ("quot;) are selected because they have large
    // Hamming distance (http://en.wikipedia.org/wiki/Hamming_distance)

    for (int i = 0; i < key.length(); i++) {
        innerPadding[i] = innerPadding[i] ^ key.at(i); // XOR operation between every byte in key and innerpadding, of key length
        outerPadding[i] = outerPadding[i] ^ key.at(i); // XOR operation between every byte in key and outerpadding, of key length
    }

    // result = hash ( outerPadding CONCAT hash ( innerPadding CONCAT baseString ) ).toBase64
    QByteArray total = outerPadding;
    QByteArray part = innerPadding;
    part.append(baseString);
    total.append(QCryptographicHash::hash(part, QCryptographicHash::Sha1));
    QByteArray hashed = QCryptographicHash::hash(total, QCryptographicHash::Sha1);
    return hashed;
}

QString SPConnect::base64Decode(QString data) {
    return QByteArray::fromBase64(data.toUtf8());
}

QString SPConnect::base64Encode(QString data) {
    return data.toUtf8().toBase64();
}

void SPConnect::startMDNSService() {
    if(mdnsService != nullptr)
        return;
    mdnsService = new ConnectMDNSService(parent());
}

void SPConnect::stopMDNSService() {
    if(mdnsService == nullptr)
        return;
    delete mdnsService;
    mdnsService = nullptr;
}

DH * get_dh() {
    static unsigned char dh1024_p[]={
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xc9,
        0x0f, 0xda, 0xa2, 0x21, 0x68, 0xc2, 0x34, 0xc4, 0xc6,
        0x62, 0x8b, 0x80, 0xdc, 0x1c, 0xd1, 0x29, 0x02, 0x4e,
        0x08, 0x8a, 0x67, 0xcc, 0x74, 0x02, 0x0b, 0xbe, 0xa6,
        0x3b, 0x13, 0x9b, 0x22, 0x51, 0x4a, 0x08, 0x79, 0x8e,
        0x34, 0x04, 0xdd, 0xef, 0x95, 0x19, 0xb3, 0xcd, 0x3a,
        0x43, 0x1b, 0x30, 0x2b, 0x0a, 0x6d, 0xf2, 0x5f, 0x14,
        0x37, 0x4f, 0xe1, 0x35, 0x6d, 0x6d, 0x51, 0xc2, 0x45,
        0xe4, 0x85, 0xb5, 0x76, 0x62, 0x5e, 0x7e, 0xc6, 0xf4,
        0x4c, 0x42, 0xe9, 0xa6, 0x3a, 0x36, 0x20, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff
        /*0xFC,0x30,0xE9,0x96,0x63,0x34,0xEC,0x58,0x90,0x37,0xE2,0x56,
        0x1D,0xC4,0x00,0x14,0xD9,0x3A,0xE2,0xAF,0x01,0xD0,0xD7,0x54,
        0x2E,0x1F,0x9D,0xAE,0xA1,0x1A,0xBC,0x18,0xB6,0xB3,0x36,0xC6,
        0xB9,0x8F,0x8B,0x07,0xD3,0x3E,0x1E,0x61,0xF4,0xDC,0xAA,0x40,
        0xC1,0x1A,0xEC,0x07,0x06,0x2F,0xDB,0x65,0x87,0x2C,0x63,0xE9,
        0x9B,0x1A,0x00,0x39,0x27,0x96,0xC7,0x4E,0x4C,0x0B,0xF3,0xF1,
        0xC0,0x82,0xA3,0xD5,0x65,0x96,0xFF,0x2C,0x3D,0xF9,0x2E,0xC4,
        0x4A,0x07,0x69,0x85,0x79,0xE4,0x4C,0xD1,0x11,0xE9,0x0B,0x2D,
        0x4F,0x0D,0x14,0xDF,0xE0,0x3B,0x74,0x0E,0x6B,0xE2,0x8C,0x29,
        0xAA,0x84,0x8D,0x60,0x15,0x3B,0xD1,0xF9,0x7F,0x3B,0xAB,0x07,
        0x07,0x1E,0xFB,0xC7,0x1D,0xF7,0x9B,0x43,*/
        };
    static unsigned char dh1024_g[]={
        0x02,
        };
    DH *dh;

    if ((dh=DH_new()) == NULL) return(NULL);
    dh->p=BN_bin2bn(dh1024_p,sizeof(dh1024_p),NULL);
    dh->g=BN_bin2bn(dh1024_g,sizeof(dh1024_g),NULL);
    if ((dh->p == NULL) || (dh->g == NULL))
        { DH_free(dh); return(NULL); }
    return(dh);
}

void add_blob_length(QByteArray * ba, int length) {
    if(length < 128) {
        ba->append(length);
    } else {
        ba->append(length);
        ba->append(length >> 7);
    }
}

unsigned int read_blob_int(QByteArray &blob, unsigned int * pos) {
    unsigned char low = blob[*pos++];
    if((low & 0x80) == 0)
        return low;
    unsigned int high = blob[*pos++];
    return (high << 7) | (low & 0x7f);
}

void read_blob_bytes(QByteArray &blob, unsigned int * pos, QByteArray &data) {
    unsigned int l = read_blob_int(blob, pos);
    data.clear();
    for(int i=0;i<l;i++)
        data[i] = blob[*pos++];
    return;
}
