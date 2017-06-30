#!/usr/bin/env python3

'''
Generate an HTML table. Call each script in ./plugins and render a row
'''

import glob, os, shutil, subprocess

status_codes = ('OK', 'not started', 'starting', 'error', 'not available', '')
templatedir = os.getenv('TEMPLATEDIR', './static')


def render_template(plugins):
    with open(os.path.join(templatedir, 'status.html.template'), 'r') as f:
        template = f.read()
    return template.replace('{{Plugins}}', plugins)

def main():

    tablerows = ''
    pluginpath = os.path.join((os.path.abspath(os.path.dirname(__file__))), 'plugins')
    for filename in glob.glob(os.path.join(pluginpath, '*')):
        try:
            output = subprocess.check_output([str(filename), ])
            rc = 0
        except subprocess.CalledProcessError as e:
            output = e.output
            rc = e.returncode
        table_row = '<tr><td>{}</td><td>{}</td><td>{}</td></tr>'.format(
            filename[:-3],
            status_codes[rc],
            output.decode()
        )
        tablerows += table_row + '\n'
    html = render_template(tablerows)

    with open('/tmp/status.html', 'w', encoding="utf-8") as f:
        f.write(html)
        subprocess.call(["cp", "-r", str(os.path.join((templatedir), 'css/')), '/tmp/'])


if __name__ == '__main__':
    main()