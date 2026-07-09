from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Optional as _Optional

DESCRIPTOR: _descriptor.FileDescriptor

class RenderRequest(_message.Message):
    __slots__ = ("job_id", "source_asset_key", "target_format", "simplify_ratio", "draco_compress")
    JOB_ID_FIELD_NUMBER: _ClassVar[int]
    SOURCE_ASSET_KEY_FIELD_NUMBER: _ClassVar[int]
    TARGET_FORMAT_FIELD_NUMBER: _ClassVar[int]
    SIMPLIFY_RATIO_FIELD_NUMBER: _ClassVar[int]
    DRACO_COMPRESS_FIELD_NUMBER: _ClassVar[int]
    job_id: str
    source_asset_key: str
    target_format: str
    simplify_ratio: float
    draco_compress: bool
    def __init__(self, job_id: _Optional[str] = ..., source_asset_key: _Optional[str] = ..., target_format: _Optional[str] = ..., simplify_ratio: _Optional[float] = ..., draco_compress: bool = ...) -> None: ...

class RenderResponse(_message.Message):
    __slots__ = ("job_id", "status")
    JOB_ID_FIELD_NUMBER: _ClassVar[int]
    STATUS_FIELD_NUMBER: _ClassVar[int]
    job_id: str
    status: str
    def __init__(self, job_id: _Optional[str] = ..., status: _Optional[str] = ...) -> None: ...

class StatusRequest(_message.Message):
    __slots__ = ("job_id",)
    JOB_ID_FIELD_NUMBER: _ClassVar[int]
    job_id: str
    def __init__(self, job_id: _Optional[str] = ...) -> None: ...

class StatusUpdate(_message.Message):
    __slots__ = ("job_id", "status", "progress", "message")
    JOB_ID_FIELD_NUMBER: _ClassVar[int]
    STATUS_FIELD_NUMBER: _ClassVar[int]
    PROGRESS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    job_id: str
    status: str
    progress: float
    message: str
    def __init__(self, job_id: _Optional[str] = ..., status: _Optional[str] = ..., progress: _Optional[float] = ..., message: _Optional[str] = ...) -> None: ...
