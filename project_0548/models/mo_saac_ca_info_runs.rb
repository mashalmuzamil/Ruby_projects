class MoSaacCaInfoRuns < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :us_court_cases])
  self.table_name = 'mo_saac_ca_info_runs'
  self.inheritance_column =:_type_disabled
  self.logger = Logger.new(STDOUT)
end