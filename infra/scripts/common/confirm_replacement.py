"""Confirm file replacement action."""

from common.colors import Colors


def confirm_replacement(force: bool) -> bool:
    """
    Ask user to confirm file replacement.

    Args:
        force: If True, skip confirmation

    Returns:
        True if user confirms or force is True, False otherwise.
    """
    if force:
        return True

    print()

    while True:
        response = (
            input("Do you want to continue and replace these files? (yes/no): ")
            .strip()
            .lower()
        )

        if response in ["yes", "y"]:
            return True
        elif response in ["no", "n"]:
            print(Colors.red("Operation cancelled."))
            return False
        else:
            print("Please answer 'yes' or 'no'.")
