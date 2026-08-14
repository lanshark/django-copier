"""Type stubs for python-decouple (untyped upstream package).

Not exhaustive — covers the config()/AutoConfig/Config call surface and Csv,
which is what nearly every project actually touches. Undefined, Choices, and
the Repository* classes are typed loosely since they're rarely referenced
directly by calling code.
"""

from typing import Any, Callable, TypeVar, overload

T = TypeVar("T")

class Undefined:
    ...

undefined: Undefined

class UndefinedValueError(Exception):
    ...

class Csv:
    def __init__(
        self,
        cast: Callable[[str], Any] = ...,
        delimiter: str = ...,
        strip: str = ...,
        post_process: Callable[..., Any] = ...,
    ) -> None: ...
    def __call__(self, value: str | None) -> list[Any]: ...

class Choices:
    def __init__(
        self,
        flat: list[Any] | None = ...,
        cast: Callable[[Any], Any] = ...,
        choices: Any = ...,
    ) -> None: ...
    def __call__(self, value: Any) -> Any: ...

class Config:
    def __init__(self, repository: Any) -> None: ...

    @overload
    def __call__(self, option: str) -> str: ...
    @overload
    def __call__(self, option: str, default: T) -> str | T: ...
    @overload
    def __call__(self, option: str, *, cast: Callable[[Any], T]) -> T: ...
    @overload
    def __call__(self, option: str, default: Any, cast: Callable[[Any], T]) -> T: ...

    @overload
    def get(self, option: str) -> str: ...
    @overload
    def get(self, option: str, default: T) -> str | T: ...
    @overload
    def get(self, option: str, *, cast: Callable[[Any], T]) -> T: ...
    @overload
    def get(self, option: str, default: Any, cast: Callable[[Any], T]) -> T: ...

class RepositoryEmpty:
    def __init__(self, source: str = ..., encoding: str = ...) -> None: ...

class RepositoryIni(RepositoryEmpty):
    ...

class RepositoryEnv(RepositoryEmpty):
    ...

class RepositorySecret(RepositoryEmpty):
    def __init__(self, source: str = ...) -> None: ...

class AutoConfig:
    def __init__(self, search_path: str | None = ...) -> None: ...

    @overload
    def __call__(self, option: str) -> str: ...
    @overload
    def __call__(self, option: str, default: T) -> str | T: ...
    @overload
    def __call__(self, option: str, *, cast: Callable[[Any], T]) -> T: ...
    @overload
    def __call__(self, option: str, default: Any, cast: Callable[[Any], T]) -> T: ...

config: AutoConfig
