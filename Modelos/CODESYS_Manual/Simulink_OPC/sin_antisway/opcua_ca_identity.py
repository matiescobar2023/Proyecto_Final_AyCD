"""Identidad OPC UA de prueba firmada por una CA dedicada a la grúa STS.

Solo crea archivos locales; no instala confianza en CODESYS. Las claves
privadas quedan cifradas fuera del paquete que se comparte.
"""

from __future__ import annotations

import hashlib
import socket
from datetime import datetime, timedelta, timezone
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.x509.oid import ExtendedKeyUsageOID, NameOID


CA_CERT_FILE = "grua_sts_opcua_test_ca.der"
CA_KEY_FILE = "grua_sts_opcua_test_ca_encrypted.pem"
CLIENT_CERT_FILE = "simulink_grua_opcua_ca_signed.der"
CLIENT_KEY_FILE = "simulink_grua_opcua_ca_signed_encrypted.pem"
CRL_FILE = "grua_sts_opcua_test_ca.crl"


def _paths(storage_dir: str) -> tuple[Path, Path, Path, Path, Path]:
    folder = Path(storage_dir).expanduser().resolve()
    if not folder.is_absolute() or folder == Path(folder.anchor):
        raise ValueError("Se requiere una carpeta privada absoluta y concreta.")
    package_dir = Path(__file__).resolve().parent
    if folder == package_dir or package_dir in folder.parents:
        raise ValueError("Las claves privadas deben quedar fuera del paquete compartible.")
    return tuple(
        folder / name
        for name in (
            CA_CERT_FILE,
            CA_KEY_FILE,
            CLIENT_CERT_FILE,
            CLIENT_KEY_FILE,
            CRL_FILE,
        )
    )


def _client_uri() -> str:
    return f"urn:{socket.gethostname()}:Simulink:CODESYS-Grua:CA2026"


def provision(key_password: str, storage_dir: str) -> dict[str, str]:
    """Crea una vez la CA, un cliente firmado y una CRL vacía; no sobrescribe."""
    if not key_password:
        raise ValueError("Se requiere una contraseña para cifrar las claves privadas.")
    ca_cert_path, ca_key_path, client_cert_path, client_key_path, crl_path = _paths(storage_dir)
    paths = (ca_cert_path, ca_key_path, client_cert_path, client_key_path, crl_path)
    present = [path.exists() for path in paths]
    if any(present) and not all(present):
        raise RuntimeError("Identidad CA incompleta; no se sobrescriben archivos existentes.")

    if not any(present):
        now = datetime.now(timezone.utc)
        ca_key = rsa.generate_private_key(public_exponent=65537, key_size=4096)
        ca_name = x509.Name(
            [
                x509.NameAttribute(NameOID.COMMON_NAME, "Grua STS Simulink OPC UA Test CA 2026"),
                x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Proyecto Grua STS"),
            ]
        )
        ca_cert = (
            x509.CertificateBuilder()
            .subject_name(ca_name)
            .issuer_name(ca_name)
            .public_key(ca_key.public_key())
            .serial_number(x509.random_serial_number())
            .not_valid_before(now - timedelta(minutes=5))
            .not_valid_after(now + timedelta(days=730))
            .add_extension(x509.BasicConstraints(ca=True, path_length=0), critical=True)
            .add_extension(
                x509.KeyUsage(
                    digital_signature=False,
                    content_commitment=False,
                    key_encipherment=False,
                    data_encipherment=False,
                    key_agreement=False,
                    key_cert_sign=True,
                    crl_sign=True,
                    encipher_only=False,
                    decipher_only=False,
                ),
                critical=True,
            )
            .add_extension(
                x509.SubjectKeyIdentifier.from_public_key(ca_key.public_key()),
                critical=False,
            )
            .add_extension(
                x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_key.public_key()),
                critical=False,
            )
            .sign(ca_key, hashes.SHA256())
        )

        client_key = rsa.generate_private_key(public_exponent=65537, key_size=3072)
        client_name = x509.Name(
            [
                x509.NameAttribute(NameOID.COMMON_NAME, "Simulink Grua STS OPC UA Client CA2026"),
                x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Proyecto Grua STS"),
            ]
        )
        client_cert = (
            x509.CertificateBuilder()
            .subject_name(client_name)
            .issuer_name(ca_name)
            .public_key(client_key.public_key())
            .serial_number(x509.random_serial_number())
            .not_valid_before(now - timedelta(minutes=5))
            .not_valid_after(now + timedelta(days=365))
            .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
            .add_extension(
                x509.KeyUsage(
                    digital_signature=True,
                    content_commitment=True,
                    key_encipherment=True,
                    data_encipherment=True,
                    key_agreement=False,
                    key_cert_sign=False,
                    crl_sign=False,
                    encipher_only=False,
                    decipher_only=False,
                ),
                critical=True,
            )
            .add_extension(x509.ExtendedKeyUsage([ExtendedKeyUsageOID.CLIENT_AUTH]), critical=True)
            .add_extension(
                x509.SubjectAlternativeName(
                    [
                        x509.DNSName(socket.gethostname()),
                        x509.UniformResourceIdentifier(_client_uri()),
                    ]
                ),
                critical=True,
            )
            .add_extension(
                x509.SubjectKeyIdentifier.from_public_key(client_key.public_key()),
                critical=False,
            )
            .add_extension(
                x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_key.public_key()),
                critical=False,
            )
            .sign(ca_key, hashes.SHA256())
        )
        crl = (
            x509.CertificateRevocationListBuilder()
            .issuer_name(ca_name)
            .last_update(now - timedelta(minutes=5))
            .next_update(now + timedelta(days=365))
            .add_extension(
                x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_key.public_key()),
                critical=False,
            )
            .sign(ca_key, hashes.SHA256())
        )
        ca_cert_path.parent.mkdir(parents=True, exist_ok=True)
        ca_key_path.write_bytes(
            ca_key.private_bytes(
                serialization.Encoding.PEM,
                serialization.PrivateFormat.PKCS8,
                serialization.BestAvailableEncryption(key_password.encode("utf-8")),
            )
        )
        client_key_path.write_bytes(
            client_key.private_bytes(
                serialization.Encoding.PEM,
                serialization.PrivateFormat.PKCS8,
                serialization.BestAvailableEncryption(key_password.encode("utf-8")),
            )
        )
        ca_cert_path.write_bytes(ca_cert.public_bytes(serialization.Encoding.DER))
        client_cert_path.write_bytes(client_cert.public_bytes(serialization.Encoding.DER))
        crl_path.write_bytes(crl.public_bytes(serialization.Encoding.DER))

    return verify(key_password, storage_dir)


def verify(key_password: str, storage_dir: str) -> dict[str, str]:
    """Valida claves, firmas, URI y vigencia sin abrir conexión de red."""
    ca_cert_path, ca_key_path, client_cert_path, client_key_path, crl_path = _paths(storage_dir)
    ca_cert = x509.load_der_x509_certificate(ca_cert_path.read_bytes())
    client_cert = x509.load_der_x509_certificate(client_cert_path.read_bytes())
    crl = x509.load_der_x509_crl(crl_path.read_bytes())
    ca_key = serialization.load_pem_private_key(
        ca_key_path.read_bytes(), password=key_password.encode("utf-8")
    )
    client_key = serialization.load_pem_private_key(
        client_key_path.read_bytes(), password=key_password.encode("utf-8")
    )
    if ca_key.public_key().public_numbers() != ca_cert.public_key().public_numbers():
        raise RuntimeError("La clave privada de la CA no coincide con su certificado.")
    if client_key.public_key().public_numbers() != client_cert.public_key().public_numbers():
        raise RuntimeError("La clave privada del cliente no coincide con su certificado.")
    ca_cert.public_key().verify(
        client_cert.signature,
        client_cert.tbs_certificate_bytes,
        padding.PKCS1v15(),
        client_cert.signature_hash_algorithm,
    )
    ca_cert.public_key().verify(
        crl.signature, crl.tbs_certlist_bytes, padding.PKCS1v15(), crl.signature_hash_algorithm
    )
    if client_cert.issuer != ca_cert.subject or crl.issuer != ca_cert.subject:
        raise RuntimeError("La cadena de identidad OPC UA no coincide.")
    if datetime.now(timezone.utc) >= min(client_cert.not_valid_after_utc, ca_cert.not_valid_after_utc):
        raise RuntimeError("La identidad OPC UA ha vencido.")
    san = client_cert.extensions.get_extension_for_class(x509.SubjectAlternativeName).value
    if san.get_values_for_type(x509.UniformResourceIdentifier) != [_client_uri()]:
        raise RuntimeError("El Application URI no coincide con el certificado del cliente.")
    return {
        "ca_certificate": str(ca_cert_path),
        "ca_sha1": hashlib.sha1(ca_cert_path.read_bytes()).hexdigest(),
        "client_certificate": str(client_cert_path),
        "client_sha1": hashlib.sha1(client_cert_path.read_bytes()).hexdigest(),
        "crl": str(crl_path),
        "application_uri": _client_uri(),
    }
