# BuffActive

A lightweight, high-performance World of Warcraft addon that monitors your class buffs and displays a reminder when they're missing. Designed to work out-of-combat only, hiding during combat and re-checking on exit.

## Why use this?

**TL;DR** - never forget to maintain your class buffs again.

Stop losing track of your essential class buffs like Battle Shout, Arcane Intellect, Mark of the Wild, or Power Word: Fortitude. **BuffActive** displays a clear, visible reminder when your important buffs are missing, helping you maintain optimal performance.

## Why not just use the default UI?

Blizzard's default UI shows buffs in the top-right corner, but it's easy to miss when you're focused on combat or other UI elements. **BuffActive** provides a prominent, hard-to-miss reminder that's specifically designed to catch your attention when important buffs expire or aren't applied.

**BuffActive** goes beyond the default UI by:

- **Persistent reminders:** continues showing the missing buff message until you apply it
- **Class-specific:** automatically monitors the appropriate buffs for your class
- **Combat-aware:** hides during combat to avoid distractions and reappears when safe
- **Configurable frequency:** adjust how often the addon checks for missing buffs
- **Customizable:** add additional spells to monitor beyond the default class buffs
- **Performance-conscious:** uses efficient API calls and debouncing to minimize performance impact

## Key features

- **Class-specific monitoring:** automatically tracks the appropriate buffs for your class (Warrior: Battle Shout, Mage: Arcane Intellect, Druid: Mark of the Wild, Priest: Power Word: Fortitude)
- **Out-of-combat only:** hides during combat to avoid distractions
- **Persistent reminders:** shows a clear message when buffs are missing until applied
- **Configurable check frequency:** adjust how often the addon checks for missing buffs (1, 2, 3, 5, or 10 seconds)
- **Custom spell support:** add additional spells to monitor beyond the default class buffs
- **Smart event handling:** responds immediately to aura changes without being affected by debounce intervals
- **Performance optimized:** uses modern WoW APIs and efficient checking mechanisms

## Installation

1. Move/copy the `BuffActive` folder to your `_retail_/Interface/AddOns/` directory
2. Restart World of Warcraft or logout and login

On load/login, the addon will begin monitoring your class buffs automatically.

## Configuration

The addon requires no setup by default. It will automatically monitor the appropriate buffs for your class. However, you can customize the behavior through the standard Blizzard addon UI under `<ESCAPE>->Options->Addons->BuffActive`.

Addon options:

- **Check frequency:** Controls how often the addon checks for missing buffs (1 second, 2 seconds (default), 3 seconds, 5 seconds, or 10 seconds). Lower values update faster but use more resources.
- **Spell Override - Current Class Spells:** Shows the current class's default monitored spells and any custom spells you've added
- **Add Custom Spell ID:** Allows you to enter additional spell IDs to monitor for your class

## Command Line Options

BuffActive does not currently provide slash commands. All configuration is done through the addon options UI.

## Technical details

- **Aura monitoring:** uses modern `C_UnitAuras` API for efficient buff detection
- **Event-driven:** responds to `UNIT_AURA`, `PLAYER_REGEN_ENABLED/DISABLED`, and `PLAYER_ENTERING_WORLD` events
- **Debounce mechanism:** prevents excessive checking while allowing immediate response to aura changes
- **Class-specific:** automatically selects appropriate buffs based on your character class
- **Combat-aware:** hides during combat and resumes monitoring when out of combat
- **Performance conscious:** uses efficient API calls and minimal resource usage

### Event Handling

**BuffActive** uses a smart event system to ensure accurate buff monitoring:

- **UNIT_AURA events:** Trigger immediate buff checks when buffs are applied or removed, bypassing debounce intervals to ensure rapid changes are detected
- **PLAYER_REGEN_ENABLED:** Performs a full buff check when exiting combat
- **PLAYER_REGEN_DISABLED:** Hides the reminder message when entering combat
- **PLAYER_ENTERING_WORLD:** Initializes spell caches and performs initial buff check on login/world changes

The debounce mechanism ensures that routine checks (like those triggered by exiting combat) respect the user-configured interval, while aura change events always trigger immediate checks to prevent missing rapid buff applications or removals.

## Contributing

Contributions to improve this tool are welcome! To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes to the source code or documentation
4. Test with various class configurations and buff scenarios
5. Submit a pull request with a clear description of the improvements

Please ensure your changes maintain compatibility with existing functionality and follows Lua best practices.

## Bugs and new features

Found a bug or want to submit a feature request?
[open an issue here](https://github.com/ExponentiallyDigital/BuffActive/issues)

## Support

This tool is unsupported and provided as-is. Use at your own risk.

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

Copyright (C) 2026 ArcNineOhNine
