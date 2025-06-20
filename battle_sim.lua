
-- ANSI color codes for text styling
local colors = {
  reset = "\27[0m",
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  cyan = "\27[36m",
  magenta = "\27[35m",
  bold = "\27[1m",
}

-- Utility to print colored text
local function cprint(text, color)
  color = color or colors.reset
  print(color .. text .. colors.reset)
end

-- Draw a health bar with color based on hp%
local function draw_health_bar(current, max)
  local bar_length = 20
  local filled = math.floor((current / max) * bar_length)
  local empty = bar_length - filled

  local bar = string.rep("█", filled) .. string.rep("░", empty)
  local color = colors.green
  if current / max < 0.3 then
    color = colors.red
  elseif current / max < 0.6 then
    color = colors.yellow
  end

  return color .. bar .. colors.reset
end

-- Player and Enemy classes
local Character = {}
Character.__index = Character

function Character:new(name, max_hp, attack_min, attack_max, defense)
  local obj = {
    name = name,
    max_hp = max_hp,
    hp = max_hp,
    attack_min = attack_min,
    attack_max = attack_max,
    defense = defense,
    potions = 3,
  }
  setmetatable(obj, self)
  return obj
end

function Character:is_alive()
  return self.hp > 0
end

function Character:attack(target)
  local base_dmg = math.random(self.attack_min, self.attack_max)
  local dmg = math.max(0, base_dmg - target.defense)
  target.hp = math.max(0, target.hp - dmg)
  return dmg
end

function Character:use_potion()
  if self.potions > 0 then
    local heal = math.min(30, self.max_hp - self.hp)
    self.hp = self.hp + heal
    self.potions = self.potions - 1
    return heal
  end
  return 0
end

-- Game State
local player = Character:new("Hero", 100, 12, 18, 5)
local enemies = {
  Character:new("Shadow Beast", 60, 8, 14, 3),
  Character:new("Fire Wraith", 50, 10, 16, 2),
}

-- Clear console function (works in ZeroBrane terminal)
local function clear_console()
  -- ANSI escape to clear screen and move cursor home
  io.write("\27[2J\27[H")
end

-- Print status info (player + enemies)
local function print_status()
  clear_console()
  cprint("=== PLAYER STATUS ===", colors.bold)
  print(string.format("HP: %3d / %3d %s", player.hp, player.max_hp, draw_health_bar(player.hp, player.max_hp)))
  print(string.format("DEF: %d", player.defense))
  print(string.format("Potions: %d\n", player.potions))

  cprint("=== ENEMIES ===", colors.bold)
  for i, e in ipairs(enemies) do
    if e:is_alive() then
      print(string.format("%d) %s - HP: %3d / %3d %s", i, e.name, e.hp, e.max_hp, draw_health_bar(e.hp, e.max_hp)))
    else
      print(string.format("%d) %s - " .. colors.red .. "DEFEATED" .. colors.reset, i, e.name))
    end
  end
  print("")
end

-- Check if all enemies dead
local function all_enemies_defeated()
  for _, e in ipairs(enemies) do
    if e:is_alive() then return false end
  end
  return true
end

-- Player turn: get valid input and act
local function player_turn()
  while true do
    cprint("Choose your action:", colors.cyan)
    cprint("[1] Attack Shadow Beast", colors.magenta)
    cprint("[2] Attack Fire Wraith", colors.magenta)
    cprint("[3] Use Potion", colors.magenta)
    io.write("Your move (1-3): ")
    local choice = io.read()
    if choice == "1" or choice == "2" then
      local enemy = enemies[tonumber(choice)]
      if not enemy:is_alive() then
        cprint("That enemy is already defeated! Choose another action.\n", colors.red)
      else
        local dmg = player:attack(enemy)
        cprint(string.format("You attacked %s for %d damage!\n", enemy.name, dmg), colors.green)
        break
      end
    elseif choice == "3" then
      local healed = player:use_potion()
      if healed > 0 then
        cprint(string.format("You used a potion and healed %d HP!\n", healed), colors.green)
        break
      else
        cprint("You have no potions left!\n", colors.red)
      end
    else
      cprint("Invalid input! Please enter 1, 2, or 3.\n", colors.red)
    end
  end
end

-- Enemy AI turn
local function enemies_turn()
  for _, e in ipairs(enemies) do
    if e:is_alive() then
      local dmg = e:attack(player)
      cprint(string.format("%s attacked you for %d damage!\n", e.name, dmg), colors.red)
    end
  end
end

-- Main Game Loop
local function game_loop()
  while player:is_alive() and not all_enemies_defeated() do
    print_status()
    player_turn()
    if all_enemies_defeated() then break end
    enemies_turn()
    if not player:is_alive() then break end
  end

  print_status()
  if player:is_alive() then
    cprint("🎉 You have defeated all enemies! Victory!", colors.green)
  else
    cprint("💀 You have been defeated... Game Over.", colors.red)
  end
end

-- Welcome message and start
clear_console()
cprint("Welcome to the Advanced Text-Based RPG Battle Simulator!", colors.bold)
cprint("Press Enter to start...", colors.cyan)
io.read()

-- Start game
game_loop()
