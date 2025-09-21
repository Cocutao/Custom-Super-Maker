# 🚀 Custom ROM Your New Samsung Laggy Budget Devices NOW

# 🛑 STOP - READ THIS FIRST
This tool ONLY works with ext4 ROMs. If your ROM uses erofs, it WILL FAIL.
Don't skip this warning then complain in issues when it doesn't work.


Tired of your Samsung budget phone lagging like it's stuck in molasses? This GitHub Actions workflow is your ticket to reviving devices like the Galaxy A04s, A05, A05s, A06, A16—or any Samsung phone with a super partition and Project Treble support (sorry A12 users, check compatibility first).

It replaces the bloated stock system with a lightweight custom ROM by rebuilding your super.img. No complex setup. No terminal sorcery. Just a few clicks and URLs.

---

## 🛠️ Why Is This Even Necessary?

### 0.1. "Why not just use TWRP?"

Because Google made modding hell. They introduced the super partition, which crams system, product, system_ext, and more into a dynamic container. It's great for OTA updates, horrible for custom ROM flashing.

> Samsung didn't lock you down—Google did, by inventing this overcomplicated super partition setup.

TWRP usually doesn't work well with it, and guess what? Most Samsung budget phones don't even get official TWRP builds.

### 0.2. "What's a Super Partition?"

Think of it as Google's "smart" storage container that dynamically resizes and holds multiple partitions. Sounds cool, but it makes modding and flashing a nightmare.

---

## ✅ How to Use

1. **Fork or Clone This Repo**: Add it to your GitHub account.

2. **Go to the "Actions" Tab** on your forked repo.

3. **Select the Workflow**: Choose "Android Super Partition Repack (Build & Release)".

4. **Click "Run Workflow"** and fill in:
   - **For Samsung A04s**: Enable the "Use pre-configured Samsung A04s firmware" option (no need for stock firmware URL!)
   - **Stock Firmware URL**: Direct download link to your firmware (skip if using A04s option)
   - **Custom System URL**: Treble-compatible ROM (.img, .img.xz, .img.gz, or .zip with system.img inside). Use a ROM with equal or higher Android version than your stock firmware.
   - **Optional settings**:
     - **Empty Product/System_ext**: Use empty product.img or system_ext.img if needed for compatibility.
     - **Silent Mode**: Reduces log spam (enabled by default).
     - **Writable Partitions**: Enables read-write system (only useful if you modify fstab).
     - **Purge All**: Deletes temporary files after the build to save space (enabled by default).

   > ⚠️ You can leave most options at default unless you know what you're doing.

5. **Wait 10–20 Minutes**: After the run, download the repacked super image from the GitHub Release or Artifacts section.

6. **Flash the Repacked Super Image**:
   - **Odin users**: Extract the .tar file and flash it using the AP slot.
   - **Heimdall users**: Extract and use the .img file directly.

7. **Reboot to Recovery and Format Data**:
   - Keep your phone connected via USB.
   - Hold Vol DOWN + Power, then switch to Vol UP + Power to enter Recovery.
   - Wipe data to avoid boot loops or soft-bricks.

---

## 🖼️ How to Get the Download Links (Tutorial)

**NEW**: For Samsung Galaxy A04s (64GB) users, you can now skip this entire section! Just enable the "Use pre-configured Samsung A04s firmware" option in the workflow.

For other devices, follow these example steps and screenshots to get the correct download links for your stock firmware:

![alt text](pic/pic1.png)

![alt text](pic/pic2.png)

![alt text](pic/pic3.png)

![alt text](pic/pic4.png)

![alt text](pic/pic5.png)

![alt text](pic/pic6.png)

![alt text](pic/pic7.png)

![alt text](pic/pic8.png)

![alt text](pic/pic9.png)

![alt text](pic/pic10.png)

![alt text](pic/pic11.png)

![alt text](pic/pic12.png)

![alt text](pic/pic13.png)

![alt text](pic/pic14.png)

---

## ✨ Features

✅ **Supports Samsung budget phones**: A04s, A05, A05s, A06, A16, and more.

✅ **Pre-configured A04s support**: No complex firmware hunting for Galaxy A04s (64GB) users!

📦 **Accepts .img, .img.xz, .img.gz, or .zip** (with system.img) custom ROMs.

💨 **Replaces Samsung's bloated OneUI** with clean, fast ROMs like LineageOS, Pixel Experience, or Miku UI.

💾 **Caches stock firmware** for future builds to reduce download time.

🧹 **Auto-cleans space** on GitHub Actions to prevent build failures.

🧠 **Includes advanced options** like writable partitions and empty overlays.

🖥️ **Runs 100% in the cloud**—no tools needed on your PC.

🏷️ **Custom branding**: Automatically adds `ro.build.id=Built.By.Minh2077.Script` to your build.prop.

⚡ **Performance improvements**: Faster workflow execution and smaller output files.

---

## 📦 Requirements

A Samsung device with:
- Super partition
- Project Treble support

Direct URLs to:
- Your stock firmware (AP_*.tar.md5) - **OR** use the A04s pre-config option
- A custom system image (system.img or .zip with it inside)

Some basic flashing knowledge (Odin or Heimdall)

---

## 🧙 How It Works

1. **Downloads & Extracts**:
   - Downloads stock firmware (from URL or pre-configured A04s firmware) and custom ROM.
   - Extracts the original super.img from the AP_*.tar.md5.
   - Prepares and decompresses your custom ROM as needed.

2. **Frees Up Space**:
   - Cleans up GitHub runner files.
   - Deletes unnecessary packages and files to avoid "no space" errors.

3. **System Modification**:
   - Uses advanced Docker-based techniques to modify build.prop for custom branding.
   - Bypasses mounting restrictions with direct filesystem manipulation.

4. **Repacking Process**:
   - Runs repacksuper.sh with your custom system.img.
   - Applies selected options like empty product.img, writable mode, etc.

5. **Packaging & Release**:
   - Verifies the repacked image was created.
   - Builds a .tar for Odin flashing.
   - Automatically creates GitHub releases with download links.

6. **Caching & Cleanup**:
   - Stores the stock firmware for later runs.
   - Cleans temp files to keep things efficient.

---

## 🧯 Troubleshooting

- **"No space left on device"**: Try smaller firmware or check logs—GitHub storage is limited.
- **"AP file not found"**: Make sure you're using the AP_*.tar.md5 file, not just any firmware blob.
- **"Unsupported file format"**: Use a proper .img, .xz, .gz, or .zip with system.img inside.
- **Not booting?**: Format data in recovery, check your ROM architecture (arm64-ab), and ensure the Android version matches or exceeds stock.
- Btw i recommend using an custom ROM using ext4, erofs wont work

---

## 📜 License

This workflow is licensed under the GNU GPL v3 License.
The repacksuper.sh script is originally by Uluruman.

---

## 🙏 Thanks

Huge thanks to Uluruman for the original repacking script that powers this workflow.

---

## 👷 Contributing

Found a bug? Got a feature idea?
PRs and Issues are welcome—let's fix laggy Samsungs together.

---

## ⚠️ Disclaimer

> **I am not responsible for bricked devices, dead SD cards, thermonuclear war, or you getting fired because the alarm app failed. Please do some research if you have any concerns about features included in this workflow before using it! YOU are choosing to make these modifications, and if you point the finger at me for messing up your device, I will laugh at you.**
>
> **Seriously, I put a giant warning at the top about ext4 vs erofs. If you ignore it, use an erofs ROM anyway, then come whining in the issues that it doesn't work - I will close your issue, laugh at you, and probably add you to the hall of shame. This isn't rocket science, people.**
>
> **Flashing custom firmware voids warranties, can permanently brick devices, and requires basic reading comprehension. If you don't have the last one, maybe stick to TikTok instead of modding phones.**
