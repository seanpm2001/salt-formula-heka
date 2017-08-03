-- Copyright 2016 Mirantis, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
local l      = require 'lpeg'
local utils  = require 'lma_utils'
l.locale(l)

local contrail   = require 'contrail_patterns'

local msg = {
    Timestamp   = nil,
    Type        = 'log',
    Hostname    = nil,
    Payload     = nil,
    Pid         = nil,
    Fields      = nil,
    Severity    = 6,
}

function process_message ()
    local log = read_message("Payload")
    local logger = read_message("Logger")
    local m = contrail.LogGrammar:match(log)
    msg.Fields = {}
    if not m then
        m = contrail.GenericGrammar:match(log)
        if not m then
            return -1, string.format("Failed to parse %s log: %s", logger, string.sub(log, 1, 64))
        end
        msg.Fields.severity_label = 'ERROR'
    else
        msg.Fields.severity_label = 'INFO'
    end
    msg.Payload = m.Message
    msg.Severity = utils.label_to_severity_map[msg.Fields.severity_label]
    msg.Timestamp = m.Timestamp
    msg.Fields.programname = m.Module
    utils.inject_tags(msg)
    return utils.safe_inject_message(msg)
end
