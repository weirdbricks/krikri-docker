# Minitest has no per-file discovery (it registers every test in-process and
# runs them from an at_exit hook), so one entrypoint requires them all:
#     crystal run test/all_test.cr
require "./test_helper"

require "./containers_test"
require "./fixtures_test"
require "./images_test"
require "./networks_test"
require "./requests_test"
require "./system_test"
require "./types_test"
require "./url_test"
require "./volumes_test"
