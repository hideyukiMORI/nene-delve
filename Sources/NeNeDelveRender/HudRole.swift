/// HUD の字の明るさ。地は塗らない。薄い字も地に対して 4.5 を割らない。
enum HudRole: Equatable {
  case value
  case label
  case flash
  case alarm
  case firm
  case mid
  case soft
  case faint
  case alarmSoft
}
