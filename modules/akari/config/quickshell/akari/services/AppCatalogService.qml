pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var apps: []

    function refresh() {
        if (!scanProc.running) scanProc.running = true
    }

    function launch(appItem) {
        if (!appItem) return
        if (appItem.terminal) {
            Quickshell.execDetached(["env", "GTK_IM_MODULE=fcitx", "QT_IM_MODULE=fcitx", "kitty", "-e", "bash", "-lc", appItem.execCmd])
        } else {
            Quickshell.execDetached(["env", "GTK_IM_MODULE=fcitx", "QT_IM_MODULE=fcitx", "bash", "-lc", "nohup " + appItem.execCmd + " >/dev/null 2>&1 &"])
        }
    }

    property Process scanProc: Process {
        command: [
            "python3", "-c",
            "import configparser, glob, json, os, re\n" +
            "dirs = [\n" +
            "    os.path.expanduser('~/.local/share/applications'),\n" +
            "    '/var/lib/flatpak/exports/share/applications',\n" +
            "    '/usr/local/share/applications',\n" +
            "    '/usr/share/applications',\n" +
            "]\n" +
            "seen = set()\n" +
            "items = []\n" +
            "for d in dirs:\n" +
            "    if not os.path.isdir(d): continue\n" +
            "    for p in sorted(glob.glob(os.path.join(d, '*.desktop'))):\n" +
            "        fid = os.path.basename(p)\n" +
            "        if fid in seen: continue\n" +
            "        cp = configparser.ConfigParser(interpolation=None, strict=False)\n" +
            "        try:\n" +
            "            cp.read(p, encoding='utf-8')\n" +
            "        except Exception:\n" +
            "            continue\n" +
            "        if 'Desktop Entry' not in cp: continue\n" +
            "        sec = cp['Desktop Entry']\n" +
            "        if sec.get('Type', '') != 'Application': continue\n" +
            "        if sec.get('NoDisplay', 'false').lower() == 'true': continue\n" +
            "        if sec.get('Hidden', 'false').lower() == 'true': continue\n" +
            "        exec_raw = sec.get('Exec', '').strip()\n" +
            "        if not exec_raw: continue\n" +
            "        exec_clean = re.sub(r'\\s+%[fFuUdDnNickvm]', '', exec_raw).strip()\n" +
            "        first_tok = exec_clean.split()[0].strip('\"') if exec_clean else fid\n" +
            "        bin_name = os.path.basename(first_tok)\n" +
            "        if bin_name == 'env' and len(exec_clean.split()) > 1:\n" +
            "            for tok in exec_clean.split()[1:]:\n" +
            "                if '=' not in tok:\n" +
            "                    bin_name = os.path.basename(tok.strip('\"'))\n" +
            "                    break\n" +
            "        name_ja = sec.get('Name[ja]', '') or sec.get('Name', '')\n" +
            "        name_en = sec.get('Name', '')\n" +
            "        sub = sec.get('GenericName[ja]', '') or sec.get('Comment[ja]', '') or sec.get('GenericName', '') or sec.get('Comment', '') or 'アプリケーション'\n" +
            "        cats = [c.lower() for c in sec.get('Categories', '').split(';') if c]\n" +
            "        kw = sec.get('Keywords[ja]', '') + ' ' + sec.get('Keywords', '') + ' ' + name_en\n" +
            "        seen.add(fid)\n" +
            "        items.append({\n" +
            "            'id': fid,\n" +
            "            'name': name_ja,\n" +
            "            'subtitle': sub,\n" +
            "            'bin': bin_name,\n" +
            "            'execCmd': exec_clean,\n" +
            "            'icon': sec.get('Icon', ''),\n" +
            "            'categories': cats,\n" +
            "            'keywords': kw.lower(),\n" +
            "            'terminal': sec.get('Terminal', 'false').lower() == 'true'\n" +
            "        })\n" +
            "items.sort(key=lambda x: x['name'].lower())\n" +
            "print(json.dumps(items, ensure_ascii=False))\n"
        ]
        property string _buf: ""
        stdout: SplitParser {
            onRead: line => { scanProc._buf += line }
        }
        onExited: exitCode => {
            if (exitCode === 0 && scanProc._buf !== "") {
                try {
                    root.apps = JSON.parse(scanProc._buf)
                } catch (e) {}
            }
            scanProc._buf = ""
        }
    }

    Component.onCompleted: refresh()
}
