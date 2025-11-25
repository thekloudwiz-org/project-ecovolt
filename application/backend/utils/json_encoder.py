"""
JSON Encoder Utilities
Handles serialization of special types like Decimal, datetime, UUID
"""

import json
from decimal import Decimal
from datetime import datetime, date
from uuid import UUID


class DecimalEncoder(json.JSONEncoder):
    """JSON encoder that handles Decimal, datetime, and UUID types"""
    
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        if isinstance(obj, (datetime, date)):
            return obj.isoformat()
        if isinstance(obj, UUID):
            return str(obj)
        return super(DecimalEncoder, self).default(obj)


def json_dumps(obj, **kwargs):
    """
    JSON dumps with Decimal/datetime/UUID support
    
    Usage:
        from utils.json_encoder import json_dumps
        json_dumps({'price': Decimal('10.50')})
    """
    return json.dumps(obj, cls=DecimalEncoder, **kwargs)
