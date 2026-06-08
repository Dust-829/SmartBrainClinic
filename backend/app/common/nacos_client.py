import logging
import random
import threading

try:
    import nacos
    NACOS_AVAILABLE = True
except ImportError:
    NACOS_AVAILABLE = False

from app.common.config import BaseMicroserviceSettings

logger = logging.getLogger("nacos_client")
logging.basicConfig(level=logging.INFO)

class NacosManager:
    _instance = None
    _lock = threading.Lock()

    def __new__(cls):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super(NacosManager, cls).__new__(cls)
                cls._instance._init_client()
            return cls._instance

    def _init_client(self):
        self.settings = BaseMicroserviceSettings()
        self.server_addresses = self.settings.NACOS_SERVER_ADDR
        self.namespace = self.settings.NACOS_NAMESPACE
        self.client = None
        self.is_connected = False
        
        if NACOS_AVAILABLE:
            try:
                # Nacos client initialization
                self.client = nacos.NacosClient(self.server_addresses, namespace=self.namespace)
                self.is_connected = True
                logger.info(f"Nacos client initialized successfully connected to {self.server_addresses}")
            except Exception as e:
                logger.error(f"Failed to connect to Nacos server: {e}")
                self.is_connected = False
        else:
            logger.warning("nacos-sdk-python not installed. Running in fallback mode.")

    def register_service(self, service_name: str, ip: str, port: int):
        if self.client and self.is_connected:
            try:
                self.client.add_naming_instance(service_name, ip, port)
                logger.info(f"Successfully registered {service_name} at {ip}:{port} to Nacos.")
            except Exception as e:
                logger.error(f"Failed to register service {service_name} to Nacos: {e}")
        else:
            logger.warning(f"Nacos not available. Skipping registration for {service_name}.")

    def deregister_service(self, service_name: str, ip: str, port: int):
        if self.client and self.is_connected:
            try:
                self.client.remove_naming_instance(service_name, ip, port)
                logger.info(f"Successfully deregistered {service_name} at {ip}:{port} from Nacos.")
            except Exception as e:
                logger.error(f"Failed to deregister service {service_name} from Nacos: {e}")

    def get_service_url(self, service_name: str, fallback_url: str) -> str:
        """
        Get service instance URL from Nacos.
        If Nacos is down or no instance is found, returns fallback_url.
        """
        if self.client and self.is_connected:
            try:
                instances = self.client.list_naming_instance(service_name, healthy_only=True)
                if instances and instances.get("hosts"):
                    hosts = instances.get("hosts")
                    # Simple Random Load Balancing
                    host = random.choice(hosts)
                    ip = host.get("ip")
                    port = host.get("port")
                    return f"http://{ip}:{port}"
            except Exception as e:
                logger.error(f"Error fetching service {service_name} from Nacos: {e}")
        
        # Fallback to local config / ENV
        logger.warning(f"Using fallback URL for {service_name}: {fallback_url}")
        return fallback_url

nacos_manager = NacosManager()
