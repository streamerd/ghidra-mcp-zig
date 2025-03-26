package ghidra.plugin.mcp;

import ghidra.framework.plugintool.Plugin;
import ghidra.framework.plugintool.PluginTool;
import ghidra.framework.plugintool.PluginInfo;
import ghidra.framework.plugintool.util.PluginStatus;
import ghidra.app.plugin.PluginCategoryNames;
import ghidra.util.Msg;

@PluginInfo(
    status = PluginStatus.RELEASED,
    packageName = ghidra.app.DeveloperPluginPackage.NAME,
    category = PluginCategoryNames.ANALYSIS,
    shortDescription = "MCP Server Plugin",
    description = "Starts an MCP server to expose program data."
)
public class GhidraMCPPlugin extends Plugin {

    public GhidraMCPPlugin(PluginTool tool) {
        super(tool);
        Msg.info(this, "GhidraMCPPlugin loaded!");
        // TODO: Initialize MCP server
    }

    @Override
    public void init() {
        super.init();
        // TODO: Start MCP server
    }

    @Override
    public void dispose() {
        // TODO: Clean up MCP server
        super.dispose();
    }
} 