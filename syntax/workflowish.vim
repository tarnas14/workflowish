if exists("b:current_syntax")
  finish
endif

syn match WFNoteDot /^\s*\*/
hi def link WFNoteDot Constant

syn match WFNote /^\s*\*(.*)/
hi def link WFNote  Question

syn match WFTag  /#[a-zA-Z0-9_-]*/
hi def link WFTag String

syn match WFDoneLine /^\s*-.*$/
hi def link WFDoneLine Comment

syn match WFComment /^\s*\\.*$/
hi def link WFComment Title

syn match WFToDo /^\s*+.*$/
hi def link WFToDo SignColumn

hi! link Folded Function

let b:current_syntax = "workflowish"
