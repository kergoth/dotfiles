# Multi-line error, mode 1
defimpl Dangerous, for: Ninja do
  def attack(weapon = %Weapon{}, defender = %Ninja{}) do
    # There is a bug here (attack/0 doesn't exist), this will make warrior.ex crash
    [attack, defender]
  end
end
