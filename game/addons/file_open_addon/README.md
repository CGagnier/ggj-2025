# Godot file autoopen addon

The current behavior in Godot 4.3 when creating a script via the create script dialog box (usually, for me, by right-clicking in the filesystem browser and selecting create new -> script) is to create the script, but not to open it in the editor. I find this very frustrating because when I create a script, I generally want to start editing it right away, so the extra clicks seem extraneous. Also, I've often searched for the folder I'm creating the script in in the filesystem browser, and so my workflow tends to be:

1. search in filesystem for the folder I want to create a script in
2. right-click to create the script and fill out the dialog box
3. clear my search results
4. search for the script
5. open the script
6. edit the script

This addon eliminates steps 3-5 in this process by automatically opening any files with ".gd" or ".cs" extension in the editor immediately after they are created. And there was much rejoicing.

Originally, I created a [godot proposal](https://github.com/godotengine/godot-proposals/discussions/11428) for this one (and I still think it should be the default behavior), but I thought about it for a while and figured it would probably be a fairly simple addon.

This is my first foray into creating addons for Godot, so it's pretty basic at the moment. I struggled a little to find what I was looking for in the Godot docs on this one, and I admit, I ended up getting some help from ChatGPT, which was ultimately helpful, although it does seem to mash GDScript 3 and 4 together quite a bit. I'm open to suggestions for configuration options. Right now, I just want to test it myself and have others test it as well. I'd appreciate any feedback.

## Installation 

Pretty simple. Just create an "addons" folder at the top level of your Godot project, and drop the addons/file_open_addon directory from this git repo into that directory. Then you should just be able to go to your project settings in Godot, select the "plugins" tab, and activate the "auto_open_script" plugin.

