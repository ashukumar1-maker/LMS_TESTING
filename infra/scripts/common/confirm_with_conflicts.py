"""Confirm action when conflicts are detected."""

from common.colors import Colors


def confirm_with_conflicts(message: str) -> bool:
    """
    Ask user to confirm action when conflicts are detected.

    Args:
        message: Warning message to display

    Returns:
        True if user confirms, False otherwise.
    """
    print(Colors.yellow(message))

    while True:
        response = input("Do you want to proceed anyway? (yes/no): ").strip().lower()

        if response in ["yes", "y"]:
            return True
        elif response in ["no", "n"]:
            print(Colors.red("Operation cancelled."))
            return False
        else:
            print("Please answer 'yes' or 'no'.")
