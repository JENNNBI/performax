# 🔴 Notification Badge - Quick Reference

## 🎯 **WHAT IT DOES**

Shows a **red dot** on the user's avatar when they have completed quests waiting to be claimed.

---

## 📍 **WHERE IT APPEARS**

### **1. Home Screen (Top-Right Avatar)**
```
┌─────────────────────────┐
│ [≡]   PROFILIM   [👤🔴]│ ← Red dot here!
└─────────────────────────┘
```

### **2. Profile Home Screen (Speech Bubble)**
```
    ┌──────────────────────────┐🔴
    │ ✨ Günlük görevlerin var!│ ← Red dot here!
    └────▼─────────────────────┘
      👤
```

---

## 🔧 **HOW IT WORKS**

```
Quest Completed → Badge Appears 🔴
User Claims Reward → Badge Disappears ⚪
```

**Logic:**
```dart
QuestService.instance.hasUnclaimedRewards
  ↓
Checks all quests: quest.isClaimable?
  ↓
If ANY quest is claimable → TRUE → Show badge
If ALL claimed → FALSE → Hide badge
```

---

## 🎨 **VISUAL SPECS**

### **Avatar Badge:**
- Size: 45% of avatar radius (proportional)
- Position: Top-right corner (top: -2, right: -2)
- Color: `Colors.redAccent`
- Border: 2px white
- Shadow: Red glow

### **Bubble Badge:**
- Size: 12x12 pixels (fixed)
- Position: Top-right inside bubble (top: 6, right: 6)
- Color: `Colors.redAccent`
- Animation: Pulsing scale (1.0 → 1.2 → 1.0)
- Duration: 800ms per cycle

---

## 🧪 **QUICK TEST**

```
1. Register → Daily Login quest completes
   ✅ Red dot appears on avatar

2. Open quest modal → Tap "Ödülü Al!"
   ✅ Rocket animation plays
   ✅ Balance +10

3. Close modal
   ✅ Red dot disappears
```

---

## 📁 **FILES**

- `lib/services/quest_service.dart` - Logic
- `lib/widgets/user_avatar_circle.dart` - Avatar badge
- `lib/widgets/quest_speech_bubble.dart` - Bubble badge

---

## 🎯 **OPTIONAL CONTROL**

```dart
// Enable badge (default)
UserAvatarCircle(
  radius: 22,
  showNotificationBadge: true, // or omit (default true)
)

// Disable badge (e.g., in Drawer)
UserAvatarCircle(
  radius: 40,
  showNotificationBadge: false,
)
```

---

**Status:** ✅ **READY**  
**The red dot will guide users to their rewards!** 🔴✨
