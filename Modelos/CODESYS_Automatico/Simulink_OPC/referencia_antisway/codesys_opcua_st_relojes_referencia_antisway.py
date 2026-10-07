"""Cliente OPC UA cifrado para el enlace Simulink--CODESYS.

La clave privada se crea cifrada fuera del paquete entregable. El certificado
del servidor se fija mediante su huella SHA-1 comprobada en CODESYS.
"""

from __future__ import annotations

import hashlib
import json
import re
import socket
import threading
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

from asyncua import ua
from asyncua.crypto.security_policies import SecurityPolicyBasic256Sha256
from asyncua.sync import Client
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import ExtendedKeyUsageOID, NameOID

import opcua_ca_identity


APP_NAME = "Simulink CODESYS Grua OPC UA Client"
CERT_FILE = "simulink_opcua_client_compat.der"
KEY_FILE = "simulink_opcua_client_compat_encrypted.pem"
SERVER_FILE = "codesys_opcua_server.der"


def _paths(storage_dir: str) -> tuple[Path, Path, Path]:
    folder = Path(storage_dir).expanduser().resolve()
    if folder == Path(folder.anchor) or not folder.is_absolute():
        raise ValueError("La carpeta privada OPC UA debe ser una ruta absoluta concreta.")
    return folder / CERT_FILE, folder / KEY_FILE, folder / SERVER_FILE


def _uri() -> str:
    return f"urn:{socket.gethostname()}:Simulink:CODESYS-Grua"


def _server_certificate(endpoint: str, expected_sha1: str) -> bytes:
    fingerprint = re.sub(r"[^0-9a-fA-F]", "", expected_sha1).lower()
    if len(fingerprint) != 40:
        raise ValueError("Se requiere la huella SHA-1 completa del servidor CODESYS.")
    discovery = Client(endpoint, timeout=4)
    try:
        endpoints = discovery.connect_and_get_server_endpoints()
        candidates = [
            item.ServerCertificate
            for item in endpoints
            if item.ServerCertificate
            and item.SecurityMode == ua.MessageSecurityMode.SignAndEncrypt
            and item.SecurityPolicyUri == SecurityPolicyBasic256Sha256.URI
        ]
        if not candidates:
            raise RuntimeError("CODESYS no anuncia Basic256Sha256/SignAndEncrypt.")
        cert_bytes = candidates[0]
        actual = hashlib.sha1(cert_bytes).hexdigest()
        if actual != fingerprint:
            raise RuntimeError(
                f"La huella del servidor no coincide: esperado {fingerprint}, recibido {actual}."
            )
        x509.load_der_x509_certificate(cert_bytes)
        return cert_bytes
    finally:
        discovery.disconnect_socket()


def _create_client_certificate(key_password: str) -> tuple[bytes, bytes]:
    if not key_password:
        raise ValueError("La clave privada requiere una contraseña no vacía.")
    now = datetime.now(timezone.utc)
    hostname = socket.gethostname()
    subject = x509.Name(
        [
            x509.NameAttribute(NameOID.COMMON_NAME, APP_NAME),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Proyecto Grua STS"),
        ]
    )
    key = rsa.generate_private_key(public_exponent=65537, key_size=3072)
    certificate = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(subject)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now - timedelta(minutes=5))
        .not_valid_after(now + timedelta(days=365))
        # CODESYS admite este perfil autofirmado cuando la compatibilidad
        # heredada está activada. path_length=0 impide emitir subordinados.
        .add_extension(x509.BasicConstraints(ca=True, path_length=0), critical=True)
        .add_extension(
            x509.KeyUsage(
                digital_signature=True,
                content_commitment=True,
                key_encipherment=True,
                data_encipherment=True,
                key_agreement=False,
                key_cert_sign=True,
                crl_sign=False,
                encipher_only=False,
                decipher_only=False,
            ),
            critical=True,
        )
        .add_extension(x509.ExtendedKeyUsage([ExtendedKeyUsageOID.CLIENT_AUTH]), critical=False)
        .add_extension(
            x509.SubjectAlternativeName(
                [x509.DNSName(hostname), x509.UniformResourceIdentifier(_uri())]
            ),
            critical=False,
        )
        .sign(key, hashes.SHA256())
    )
    key_bytes = key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.BestAvailableEncryption(key_password.encode("utf-8")),
    )
    cert_bytes = certificate.public_bytes(serialization.Encoding.DER)
    return cert_bytes, key_bytes


def provision(
    endpoint: str, expected_server_sha1: str, key_password: str, storage_dir: str
) -> dict[str, str]:
    """Verifica el servidor y crea una sola vez el certificado de cliente."""
    cert_path, key_path, server_path = _paths(storage_dir)
    server_bytes = _server_certificate(endpoint, expected_server_sha1)
    cert_path.parent.mkdir(parents=True, exist_ok=True)

    if cert_path.exists() != key_path.exists():
        raise RuntimeError("Falta uno de los archivos de identidad OPC UA; no se sobrescribe el otro.")
    if cert_path.exists():
        cert = x509.load_der_x509_certificate(cert_path.read_bytes())
        key = serialization.load_pem_private_key(
            key_path.read_bytes(), password=key_password.encode("utf-8")
        )
        if cert.public_key().public_numbers() != key.public_key().public_numbers():
            raise RuntimeError("El certificado de cliente no coincide con su clave privada.")
        if cert.not_valid_after_utc <= datetime.now(timezone.utc):
            raise RuntimeError("El certificado de cliente ha vencido.")
    else:
        cert_bytes, key_bytes = _create_client_certificate(key_password)
        key_path.write_bytes(key_bytes)
        cert_path.write_bytes(cert_bytes)

    if server_path.exists():
        if server_path.read_bytes() != server_bytes:
            raise RuntimeError("Cambió el certificado del servidor; verifique la huella en CODESYS.")
    else:
        server_path.write_bytes(server_bytes)

    return {
        "client_certificate": str(cert_path),
        "client_sha1": hashlib.sha1(cert_path.read_bytes()).hexdigest(),
        "server_sha1": hashlib.sha1(server_bytes).hexdigest(),
    }


def inspect_client_identity(key_password: str, storage_dir: str) -> dict[str, str]:
    """Comprueba sin conectar qué certificado cargará el cliente OPC UA."""
    cert_path, key_path, server_path = _paths(storage_dir)
    client = Client("opc.tcp://127.0.0.1:4840", timeout=4)
    client.application_uri = _uri()
    client.set_security(
        SecurityPolicyBasic256Sha256,
        certificate=str(cert_path),
        private_key=str(key_path),
        private_key_password=key_password,
        server_certificate=str(server_path),
        mode=ua.MessageSecurityMode.SignAndEncrypt,
    )
    configured = hashlib.sha1(client.aio_obj.security_policy.host_certificate).hexdigest()
    expected = hashlib.sha1(cert_path.read_bytes()).hexdigest()
    return {
        "configured_sha1": configured,
        "expected_sha1": expected,
        "matches": str(configured == expected),
        "application_uri": client.application_uri,
    }


def probe(
    endpoint: str,
    expected_server_sha1: str,
    username: str,
    password: str,
    key_password: str,
    storage_dir: str,
) -> dict[str, object]:
    """Prueba mínima: leer el latido PLC y alternar solo el latido Simulink."""
    if not username or not password:
        raise ValueError("Se requiere un usuario y una contraseña OPC UA del dispositivo.")
    provision(endpoint, expected_server_sha1, key_password, storage_dir)
    cert_path, key_path, server_path = _paths(storage_dir)
    client = Client(endpoint, timeout=4)
    client.application_uri = _uri()
    client.set_user(username)
    client.set_password(password)
    client.set_security(
        SecurityPolicyBasic256Sha256,
        certificate=str(cert_path),
        private_key=str(key_path),
        private_key_password=key_password,
        server_certificate=str(server_path),
        mode=ua.MessageSecurityMode.SignAndEncrypt,
    )
    return _probe_with_client(client)


def probe_ca(
    endpoint: str,
    expected_server_sha1: str,
    username: str,
    password: str,
    key_password: str,
    storage_dir: str,
) -> dict[str, object]:
    """Prueba mínima con certificado cliente firmado por la CA dedicada."""
    if not username or not password:
        raise ValueError("Se requiere un usuario y una contraseña OPC UA del dispositivo.")
    identity = opcua_ca_identity.verify(key_password, storage_dir)
    server_bytes = _server_certificate(endpoint, expected_server_sha1)
    _, _, _, client_key_path, _ = opcua_ca_identity._paths(storage_dir)
    client = Client(endpoint, timeout=4)
    client.application_uri = identity["application_uri"]
    client.set_user(username)
    client.set_password(password)
    client.set_security(
        SecurityPolicyBasic256Sha256,
        certificate=identity["client_certificate"],
        private_key=str(client_key_path),
        private_key_password=key_password,
        server_certificate=server_bytes,
        mode=ua.MessageSecurityMode.SignAndEncrypt,
        # La CA ya está instalada en CODESYS. Enviar aquí la cadena completa
        # haría que OpenSecureChannel y CreateSession presenten bytes distintos
        # como certificado del cliente; CODESYS exige que sean idénticos.
        certificate_chain=[],
    )
    actual_sha1 = hashlib.sha1(client.aio_obj.security_policy.host_certificate).hexdigest()
    if actual_sha1 != identity["client_sha1"]:
        raise RuntimeError("El cliente OPC UA cargó un certificado distinto del verificado.")
    chain = client.aio_obj.security_policy.host_certificate_chain
    if chain:
        raise RuntimeError("El cliente OPC UA cargó una cadena inesperada.")
    return _probe_with_client(client)


def _probe_with_client(client: Client) -> dict[str, object]:
    try:
        client.connect()
        objects = client.nodes.objects
        gvl = _find_by_name(objects, "GVL_GRUA")
        plc = _find_by_name(gvl, "opcHeartbeatPLC")
        simulink = _find_by_name(gvl, "opcHeartbeatSimulink")
        before = bool(simulink.get_value())
        plc_value = bool(plc.get_value())
        simulink.set_value(ua.Variant(not before, ua.VariantType.Boolean))
        after = bool(simulink.get_value())
        return {
            "connected": True,
            "plc_heartbeat": plc_value,
            "simulink_heartbeat_written": after,
            "write_verified": after != before,
        }
    finally:
        client.disconnect()


def _find_by_name(root, name: str):
    pending = [root]
    seen = set()
    while pending and len(seen) < 2000:
        node = pending.pop(0)
        identifier = node.nodeid.to_string()
        if identifier in seen:
            continue
        seen.add(identifier)
        if node.read_browse_name().Name == name:
            return node
        pending.extend(node.get_children())
    raise LookupError(f"Nodo OPC UA no encontrado: {name}")


_pool_lock = threading.RLock()
_shared_pool = None


class _SharedSession:
    """Una sesion segura compartida por los dos bloques OPC UA del modelo."""

    def __init__(self, key, client, gvl):
        self.key = key
        self.client = client
        self.gvl = gvl
        self.nodes = {}
        self.references = 0
        self.valid = True
        self.exchanges = 0
        self.exchange_seconds = 0.0
        self.max_exchange_seconds = 0.0

    def start_health(self):
        if hasattr(self, "health_stop"):
            return
        self.health_stop = threading.Event()
        health_node = self.node("opcHeartbeatHealth")
        pulse_start = not bool(health_node.get_value())
        health_node.set_value(ua.Variant(pulse_start, ua.VariantType.Boolean))
        def health_loop():
            pulse = pulse_start
            while not self.health_stop.wait(0.2):
                with _pool_lock:
                    if not self.valid or self.references <= 0:
                        return
                    try:
                        pulse = not pulse
                        health_node.set_value(ua.Variant(pulse, ua.VariantType.Boolean))
                    except Exception:
                        self.valid = False
                        self.health_stop.set()
                        return

        self.health_thread = threading.Thread(target=health_loop, name="OPCUA_SaludBanco", daemon=True)
        self.health_thread.start()

    def node(self, name):
        if name not in self.nodes:
            self.nodes[name] = _find_by_name(self.gvl, name)
        return self.nodes[name]


class Bridge:
    """Puertos independientes de Simulink sobre una sola sesion OPC UA.

    Cada bloque conserva sus listas y salidas seguras. Las dos llamadas por
    muestra se serializan sobre el mismo canal cifrado y mantienen el periodo
    original de 20 ms. No se reutiliza una sesion invalidada por un error.
    """

    def __init__(
        self,
        endpoint: str,
        expected_server_sha1: str,
        username: str,
        password: str,
        key_password: str,
        storage_dir: str,
        write_names_json: str,
        read_names_json: str,
    ) -> None:
        global _shared_pool
        self._session = None
        pool_key = (
            endpoint,
            re.sub(r"[^0-9a-fA-F]", "", expected_server_sha1).lower(),
            username,
            str(Path(storage_dir).expanduser().resolve()),
            hashlib.sha256(password.encode("utf-8")).digest(),
            hashlib.sha256(key_password.encode("utf-8")).digest(),
        )
        with _pool_lock:
            if _shared_pool is not None and _shared_pool.valid:
                if _shared_pool.key != pool_key:
                    raise RuntimeError("Los bloques OPC UA usan identidades distintas.")
            else:
                identity = opcua_ca_identity.verify(key_password, storage_dir)
                server_bytes = _server_certificate(endpoint, expected_server_sha1)
                _, _, _, key_path, _ = opcua_ca_identity._paths(storage_dir)
                client = Client(endpoint, timeout=4)
                client.application_uri = identity["application_uri"]
                client.set_user(username)
                client.set_password(password)
                client.set_security(
                    SecurityPolicyBasic256Sha256,
                    certificate=identity["client_certificate"],
                    private_key=str(key_path),
                    private_key_password=key_password,
                    server_certificate=server_bytes,
                    mode=ua.MessageSecurityMode.SignAndEncrypt,
                    certificate_chain=[],
                )
                if hashlib.sha1(client.aio_obj.security_policy.host_certificate).hexdigest() != identity["client_sha1"]:
                    raise RuntimeError("El cliente OPC UA cargó un certificado distinto del verificado.")
                try:
                    client.connect()
                    gvl = _find_by_name(client.nodes.objects, "GVL_GRUA")
                except Exception:
                    client.disconnect()
                    raise
                _shared_pool = _SharedSession(pool_key, client, gvl)
            self._session = _shared_pool
            self._session.references += 1
            self.client = self._session.client
            try:
                self.write_nodes = [self._session.node(name) for name in json.loads(write_names_json)]
                self._frame_write_names = json.loads(write_names_json)
                self._frame_read_names = json.loads(read_names_json)
                self.read_nodes = [self._session.node(name) for name in json.loads(read_names_json)]
                self.write_types = [node.read_data_type_as_variant_type() for node in self.write_nodes]
                self._session.start_health()
            except Exception:
                self.close()
                raise

    def exchange(self, values_json: str) -> str:
        values = json.loads(values_json)
        if len(values) != len(self.write_nodes):
            raise ValueError("La cantidad de valores OPC UA no coincide con los nodos de escritura.")
        variants = [
            ua.Variant(_coerce_value(value, kind), kind)
            for value, kind in zip(values, self.write_types)
        ]
        global _shared_pool
        with _pool_lock:
            session = self._session
            if session is None or not session.valid:
                raise ConnectionError("La sesion OPC UA compartida no esta disponible.")
            started = time.perf_counter()
            try:
                session.client.write_values(self.write_nodes, variants)
                result = session.client.read_values(self.read_nodes)
                if "opcHeartbeatPLC" in self._frame_read_names and "opcHeartbeatSimulink" in self._frame_write_names:
                    ack_index = self._frame_read_names.index("opcHeartbeatPLC")
                    frame_value = bool(values[self._frame_write_names.index("opcHeartbeatSimulink")])
                    deadline = time.perf_counter() + 2.0
                    while bool(result[ack_index]) != frame_value:
                        if time.perf_counter() >= deadline:
                            raise TimeoutError("El PLC no confirmo la trama de simulacion")
                        time.sleep(0.001)
                        result = session.client.read_values(self.read_nodes)
            except Exception:
                session.valid = False
                if _shared_pool is session:
                    _shared_pool = None
                try:
                    session.client.disconnect()
                except Exception:
                    pass
                raise
            elapsed = time.perf_counter() - started
            session.exchanges += 1
            session.exchange_seconds += elapsed
            session.max_exchange_seconds = max(session.max_exchange_seconds, elapsed)
        return json.dumps(result, allow_nan=False)

    def close(self) -> None:
        global _shared_pool
        with _pool_lock:
            session = self._session
            if session is None:
                return
            self._session = None
            session.references -= 1
            if session.references == 0:
                if hasattr(session, "health_stop"):
                    session.health_stop.set()
                if session.valid:
                    try:
                        session.client.disconnect()
                    except Exception:
                        pass
                    finally:
                        session.valid = False
                if _shared_pool is session:
                    _shared_pool = None
                if session.exchanges:
                    average_ms = 1000.0 * session.exchange_seconds / session.exchanges
                    print(
                        f"OPCUA_POOL exchanges={session.exchanges} "
                        f"avg_ms={average_ms:.2f} "
                        f"max_ms={1000.0 * session.max_exchange_seconds:.2f}"
                    )


def _coerce_value(value, kind: ua.VariantType):
    if isinstance(value, list):
        return [_coerce_value(item, kind) for item in value]
    if kind == ua.VariantType.Boolean:
        return bool(value)
    if kind in (ua.VariantType.Float, ua.VariantType.Double):
        return float(value)
    if kind in (
        ua.VariantType.SByte,
        ua.VariantType.Byte,
        ua.VariantType.Int16,
        ua.VariantType.UInt16,
        ua.VariantType.Int32,
        ua.VariantType.UInt32,
        ua.VariantType.Int64,
        ua.VariantType.UInt64,
    ):
        return int(value)
    raise TypeError(f"Tipo de variable OPC UA no admitido para escritura: {kind}")

