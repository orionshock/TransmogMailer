# TransmogMailer

**TransmogMailer** is a World of Warcraft addon that helps you manage unneeded transmog items by identifying which characters can use them, then mailing them accordingly.

It uses **[Can I Mog It](https://www.curseforge.com/wow/addons/can-i-mog-it)** behind the scenes to determine if an item is transmoggable and whether your characters already know it.

## 🛠 Basic Usage

1. **Install Can I Mog It** alongside TransmogMailer on WoW Forever (interface `16001`).
2. Log in to **each character** you want to track. Wait a moment for *Can I Mog It* to scan that character’s known appearances.
3. Once all relevant characters have been scanned, go to **Blizzard Options → AddOns → TransmogMailer**.
4. Configure recipients, choose a collection mode, and select a modifier key. **None disables mailing.**
5. Hold the selected modifier while opening a mailbox to send eligible unbound gear. Mailing waits for confirmation after each batch of up to 12 attachments.

If a send fails or attachments change, the queue stops. Recover unsent attachments from the compose window, then reopen the mailbox to try again.

## 🔍 What It Does

- Checks if the current character needs a transmog item.
- If not, checks your configured list to see who should receive it.
- Adds that item to a mailing queue for easy sending.

## ❗ Notes

- TransmogMailer does **not** make automatic decisions or suggestions — you configure the logic yourself in the addon settings.
- Requires **Can I Mog It** to function properly.

<img src="images/interfaceOptions.jpg" alt="Interface Options" width="600" />
