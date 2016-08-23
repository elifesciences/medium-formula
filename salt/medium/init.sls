medium-repository:
    builder.git_latest:
        - name: git@github.com:elifesciences/medium.git
        - identity: {{ pillar.elife.projects_builder.key or '' }}
        - rev: {{ salt['elife.rev']() }}
        - branch: {{ salt['elife.branch']() }}
        - target: /srv/medium/
        - force_fetch: True
        - force_checkout: True
        - force_reset: True
        - fetch_pull_requests: True
        - require:
            - cmd: php-composer-1.0
            - cmd: php-puli-latest

    file.directory:
        - name: /srv/medium
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - recurse:
            - user
            - group
        - require:
            - builder: medium-repository

medium-propel-config:
    file.managed:
        - name: /srv/medium/propel.yml
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - source: salt://medium/config/srv-medium-propel.yml
        - require:
            - medium-repository

composer-install:
    cmd.run:
        {% if pillar.elife.env in ['prod', 'demo', 'end2end'] %}
        - name: composer1.0 --no-interaction install --classmap-authoritative --no-dev
        {% elif pillar.elife.env in ['ci'] %}
        - name: composer1.0 --no-interaction install --classmap-authoritative
        {% else %}
        - name: composer1.0 --no-interaction install
        {% endif %}
        - cwd: /srv/medium/
        - user: {{ pillar.elife.deploy_user.username }}

medium-nginx-vhost:
    file.managed:
        - name: /etc/nginx/sites-enabled/medium.conf
        - source: salt://medium/config/etc-nginx-sites-enabled-medium.conf
        - template: jinja
        - require:
            - nginx-config
        - listen_in:
            - service: nginx-server-service
            - service: php-fpm

medium-database:
    mysql_database.present:
        - name: medium
        - connection_pass: {{ pillar.elife.db_root.password }}
        - require:
            - mysql-ready

medium-database-user:
    mysql_user.present:
        - name: medium
        - password: medium
        - connection_pass: {{ pillar.elife.db_root.password }}
        - host: '%'
        - require:
            - mysql-ready

medium-database-access:
    mysql_grants.present:
        - user: medium
        - connection_pass: {{ pillar.elife.db_root.password }}
        - database: medium.*
        - grant: all privileges
        - host: '%'
        - require:
            - medium-database
            - medium-database-user

medium-propel:
    cmd.run:
        - user: {{ pillar.elife.deploy_user.username }}
        - cwd: /srv/medium
        - name: composer1.0 run sync
        - require:
            - install-composer
            - file: medium-propel-config

medium-cache:
    file.directory:
        - name: /srv/medium/cache
        - user: {{ pillar.elife.webserver.username }}
        - group: {{ pillar.elife.webserver.username }}
        - dir_mode: 775
        - file_mode: 664
        - recurse:
            - user
            - group
        - require:
            - medium-repository
