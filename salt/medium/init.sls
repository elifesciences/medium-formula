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
        - template: jinja
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
        - require:
            - medium-repository

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
        - name: {{ pillar.medium.db.name }}
        - connection_pass: {{ pillar.elife.db_root.password }}
        - require:
            - mysql-ready

medium-database-user:
    mysql_user.present:
        - name: {{ pillar.medium.db.user }}
        - password: {{ pillar.medium.db.password }}
        - connection_pass: {{ pillar.elife.db_root.password }}
        {% if pillar.elife.env in ['dev'] %}
        - host: '%'
        {% else %}
        - host: localhost
        {% endif %}
        - require:
            - mysql-ready

medium-database-access:
    mysql_grants.present:
        - user: {{ pillar.medium.db.user }}
        - connection_pass: {{ pillar.elife.db_root.password }}
        - database: {{ pillar.medium.db.name }}.*
        - grant: all privileges
        {% if pillar.elife.env in ['dev'] %}
        - host: '%'
        {% else %}
        - host: localhost
        {% endif %}
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
            - mysql_grants: medium-database-access

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

medium-cron:
    cron.present:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: /srv/medium/bin/update
        - special: '@hourly'
