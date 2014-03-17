class HttpMappingStatus
  PENDING = "PENDING" # it is not available yet
  OK = "OK" # it is available
  LOST = "LOST" # it was available before but now it is not
  NOT_MONITORED = "NOT_MONITORED"
end