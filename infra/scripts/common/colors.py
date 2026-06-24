"""Terminal color definitions."""

from typing import Final


class Colors:
    """ANSI color codes for terminal output."""

    RED: Final[str] = "\033[0;31m"
    GREEN: Final[str] = "\033[0;32m"
    YELLOW: Final[str] = "\033[1;33m"
    BLUE: Final[str] = "\033[0;34m"
    NC: Final[str] = "\033[0m"  # No Color / Reset

    @classmethod
    def red(cls, text: str) -> str:
        """Wrap text in red color."""
        return f"{cls.RED}{text}{cls.NC}"

    @classmethod
    def green(cls, text: str) -> str:
        """Wrap text in green color."""
        return f"{cls.GREEN}{text}{cls.NC}"

    @classmethod
    def yellow(cls, text: str) -> str:
        """Wrap text in yellow color."""
        return f"{cls.YELLOW}{text}{cls.NC}"

    @classmethod
    def blue(cls, text: str) -> str:
        """Wrap text in blue color."""
        return f"{cls.BLUE}{text}{cls.NC}"
