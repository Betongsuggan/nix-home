local keymaps = require('editor/keymappings')
local chatgpt = require("chatgpt")

chatgpt.setup({
  api_key_cmd = 'ai_key_provider',
  openai_params = {
    model = "gpt-4o",
    max_tokens = 4096,
  },
})


local function runCommand(command)
  local mode = vim.fn.mode()
  return function()
    if mode == 'v' or mode == 'V' then
      vim.cmd(":'<,'>" .. command)
    else
      vim.fn.setpos("'<", { 0, 0, 0, 0 })
      vim.fn.setpos("'>", { 0, 0, 0, 0 })
      vim.cmd(":%" .. command)
    end
  end
end

keymaps.ai_chat(function() vim.cmd('ChatGPT') end)
keymaps.ai_edit_with_instruction(function() vim.cmd('ChatGPTEditWithInstruction') end)
keymaps.ai_complete(function() vim.cmd('ChatGPTCompleteCode') end)

keymaps.ai_grammar_correction(runCommand("ChatGPTRun grammar_correction"))
keymaps.ai_translate(runCommand("ChatGPTRun translate"))
keymaps.ai_keywords(runCommand("ChatGPTRun keywords"))
keymaps.ai_docstring(runCommand("ChatGPTRun docstring"))
keymaps.ai_add_tests(runCommand("ChatGPTRun add_tests"))
keymaps.ai_optimize_code(runCommand("ChatGPTRun optimize_code"))
keymaps.ai_summarize(runCommand("ChatGPTRun summarize"))
keymaps.ai_fix_bugs(runCommand("ChatGPTRun fix_bugs"))
keymaps.ai_explain_code(runCommand("ChatGPTRun explain_code"))
keymaps.ai_readability_analysis(runCommand("ChatGPTRun code_readability_analysis"))
