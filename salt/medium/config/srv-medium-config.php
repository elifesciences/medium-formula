<?php

return [
{% if pillar.medium.iiif.base_uri %}
    'iiif' => '{{ pillar.medium.iiif.base_uri }}',
{% endif %}
];
