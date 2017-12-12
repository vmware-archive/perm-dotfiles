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
1. Add your SSH key to the machine
1. [Install Homebrew](https://brew.sh)
    - May require you to install xcode-tools independently
1. Ensure that Homebrew is correctly installed: `brew doctor`
1. Install git if necessary: `which git || brew install git`
1. Start installing our dotfiles:
    ```
    mkdir -p ~/workspace
    cd ~/workspace
    git clone git@github.com:pivotal-cf/perm-dotfiles
    cd perm-dotfiles
    make
    ```
    - You may need to re-run `make` a few times due to MacOS security restrictions and other similar problems    
1. Grant Flycut and ShiftIt "Accessibility" permisisons
1. Add Flux, Flycut, and ShiftIt to the "Login Items"
1. Customize ITerm colours, fonts, alarms, etc.
1. [Play crosswords](https://nytimes.crosswords) while you wait
