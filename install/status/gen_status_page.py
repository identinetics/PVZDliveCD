#!/usr/bin/env python3

'''
Generate an HTML table. Call each script in ./plugins and render a row
'''

import jinja2, os, shutil, subprocess
from pathlib import Path

status_codes = ('OK', 'not started', 'starting', 'error', 'not available', '')
def main():
    templatedir = os.getenv('TEMPLATEDIR', './static')
    with open(os.path.join(templatedir, 'status.html.template'), 'r') as f:
        template = jinja2.Template(f.read())

    tablerows = ''
    pluginpath = Path(os.path.abspath(os.path.dirname(__file__))) / 'plugins'
    for filename in pluginpath.glob('*'):
        try:
            output = subprocess.check_output([str(filename), ])
            rc = 0
        except subprocess.CalledProcessError as e:
            output = e.output
            rc = e.returncode
        table_row = '<tr><td>{}</td><td>{}</td><td>{}</td></tr>'.format(
            Path(filename).stem,
            status_codes[rc],
            output.decode()
        )
        tablerows += table_row + '\n'
    html = template.render(Plugins=tablerows, )

    with open('/tmp/status.html', 'w', encoding="utf-8") as f:
        f.write(html)
        subprocess.call(["cp", "-r", str(Path(templatedir) / 'css/'), '/tmp/'])


if __name__ == '__main__':
    main()