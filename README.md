# Perm Dotfiles

### Setting Up a New Worksation

**Please update this repo and README as you go if you encounter any problems!**

1. Install any OS upgrades and updates
1. Fix basic configuration:
    - Update the password for the user `pivotal`
    - Adjust mouse and keyboard preferences according to preferences
    - Customize the Dock
    - Mute the OS alarm bell
    - ...etc.
1. Add your SSH key and run the following:
    ```
    mkdir ~/workspace
    cd ~/workspace
    git clone git@github.com:pivotal-cf/perm-dotfiles
    cd perm-dotfiles
    make
    ```
    - You may need to re-run `make` a few times due to MacOS security restrictions and other similar problems
1. Run `brew link mariadb@<x.x> -f` to namespace mariadb binary to `mysql`
1. Grant Flycut and ShiftIt "Accessibility" permisisons
1. Add Flux, Flycut, and ShiftIt to the "Login Items"
1. Customize ITerm colours, fonts, alarms, etc.
1. [Play crosswords](https://nytimes.crosswords) while you wait

Note: if any installed application is not showing up in osx spotlight, run the following (reloads spotlight indexing)
```
sudo mdutil -a -i off
sudo mdutil -a -i on
```
