# ARZMOD Patcher

ARZMOD Patcher for add more fun (cleo, monetloader [lua] and AML [so] loader) in original arizona launcher (arizona-rp.com). Created by [arzmod.com](https://arzmod.com)

## Getting Started

### Prerequisites
Ensure you have the following installed:
- Python (version 3.8 or later)
- Required dependencies (install via `requirements.txt` if applicable)
- Android Sdk (build-tools)

### Steps to Use

1. Clone the repository:
   ```bash
   git clone https://github.com/idmkdev/arzmod-patcher.git
   cd arzmod-patcher
   ```

2. Configure your settings:
   - Open the `config.py` file.
   - Fill in your specific data (e.g., API keys, paths, etc.).

3. Run the patcher:
   ```bash
   python main.py
   ```

### Build Tags
- **`-release`**: Automatically publishes the client and updates the associated news about the client.
- **`-test`**: Executes a test replacement or other testing actions.

You can specify these tags when running the script to define the build behavior.

## Example Usage
```bash
python main.py -release
```
This will build the APK, publish the client, and update the news.

```bash
python main.py -test
```
This will perform a test replacement.


## Created by

- [Radare](https://t.me/ryderinc) · [ARZMOD](https://t.me/CleoArizona) Dev
