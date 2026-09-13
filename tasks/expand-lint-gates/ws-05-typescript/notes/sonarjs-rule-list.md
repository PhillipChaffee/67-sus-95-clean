# Sonarjs rule list

eslint-plugin-sonarjs: make sure that the pinned version's rule list before  promising rules. The SonarQube ids (S3776 cognitive complexity, S125 commented-out code, no-duplicate-string) do not all map 1:1 to the eslint plugin: check what the plugin actually ships and note the mapping in the README. If commented-out code is missing from the plugin, find a replacement gate or record an accepted gap (do not fake it).
