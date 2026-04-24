FROM odoo:17

USER root

COPY ./requirement.txt /tmp/requirement.txt
RUN pip3 install --no-cache-dir -r /tmp/requirement.txt && rm -f /tmp/requirement.txt

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["odoo"]
