/// The one-tap reactions shown inline in the message action sheet. Six is what
/// fits the row comfortably at the smallest supported width; everything else
/// lives behind the "+" in [kEmojiCategories].
const List<String> kQuickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

/// A named group in the full emoji picker.
class EmojiCategory {
  const EmojiCategory(this.name, this.emojis);

  final String name;
  final List<String> emojis;
}

/// The full reaction palette, grouped the way the system keyboard groups it so
/// the section a user reaches for is where they expect it.
const List<EmojiCategory> kEmojiCategories = [
  EmojiCategory('Smileys', [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '🙂', '😉', '😊', '😇', '🥰', '😍', '🤩', '😘',
    '😋', '😜', '🤪', '🤗', '🤔', '🤨', '😐', '😴',
    '😌', '😔', '😢', '😭', '😤', '😠', '🤯', '😳',
    '🥺', '😬', '🙄', '😮', '😱', '🤐', '🤫', '😷',
  ]),
  EmojiCategory('Gestures', [
    '👍', '👎', '👌', '🤌', '✌️', '🤞', '🤟', '🤘',
    '👏', '🙌', '🤝', '🙏', '💪', '👋', '🫶', '🤙',
    '☝️', '👆', '👇', '👈', '👉', '✍️', '🫡', '🤷',
  ]),
  EmojiCategory('Hearts', [
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
    '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
    '💘', '💝', '💯', '💢', '💥', '✨', '⭐', '🌟',
  ]),
  EmojiCategory('Campus', [
    '🎓', '📚', '📖', '✏️', '📝', '🖊️', '📐', '📏',
    '🎒', '🏫', '🔬', '🧪', '💻', '🖥️', '📊', '📈',
    '🗓️', '⏰', '📌', '📎', '🔖', '💡', '🧠', '🏆',
  ]),
  EmojiCategory('Celebrate', [
    '🎉', '🎊', '🥳', '🎈', '🎁', '🍾', '🥂', '🧁',
    '🎂', '🍰', '🎵', '🎶', '🕺', '💃', '🔥', '⚡',
    '🚀', '🌈', '☀️', '🌙', '❄️', '🍀', '🎯', '🎨',
  ]),
  EmojiCategory('Food', [
    '☕', '🍵', '🧋', '🥤', '🍕', '🍔', '🍟', '🌮',
    '🍜', '🍝', '🍛', '🍲', '🥗', '🍿', '🍩', '🍪',
    '🍫', '🍎', '🍌', '🍉', '🥭', '🥑', '🍇', '🍓',
  ]),
  EmojiCategory('Activity', [
    '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏸', '🏓',
    '🏏', '🥅', '🥇', '🥈', '🥉', '🏅', '🎮', '🎲',
    '♟️', '🎸', '🎤', '🎧', '🏃', '🚴', '🧘', '🏊',
  ]),
  EmojiCategory('Symbols', [
    '✅', '❌', '❓', '❗', '⚠️', '🚫', '💬', '👀',
    '🔔', '📢', '📣', '🔗', '🔒', '🔑', '♻️', '🆗',
    '🆘', '💤', '💫', '🌀', '🎃', '👻', '🤖', '👽',
  ]),
];
