import 'package:flutter/material.dart';

class StudioLocalizations {
  const StudioLocalizations._();

  static const supportedLocales = [Locale('zh'), Locale('en')];

  static String translate(String input, Locale locale) {
    if (locale.languageCode != 'en') return input;
    final exact = _english[input];
    if (exact != null) return exact;

    Match? match;
    if ((match = RegExp(r'^(\d+) 幅作品$').firstMatch(input)) != null) {
      return '${match!.group(1)} artworks';
    }
    if ((match = RegExp(r'^(\d+) 幅新画$').firstMatch(input)) != null) {
      return '${match!.group(1)} new';
    }
    if ((match = RegExp(r'^(\d+) 个收藏$').firstMatch(input)) != null) {
      return '${match!.group(1)} favorites';
    }
    if ((match = RegExp(r'^(\d+) 幅$').firstMatch(input)) != null) {
      return '${match!.group(1)} artworks';
    }
    if ((match = RegExp(r'^(\d+) 节课$').firstMatch(input)) != null) {
      return '${match!.group(1)} lessons';
    }
    if ((match = RegExp(r'^(\d+) 节$').firstMatch(input)) != null) {
      return '${match!.group(1)} lessons';
    }
    if ((match = RegExp(r'^(\d+) 分钟$').firstMatch(input)) != null) {
      return '${match!.group(1)} min';
    }
    if ((match = RegExp(r'^(\d+) 小时前$').firstMatch(input)) != null) {
      return '${match!.group(1)} hr ago';
    }
    if ((match = RegExp(r'^(\d+) 天前$').firstMatch(input)) != null) {
      return '${match!.group(1)} days ago';
    }
    if ((match = RegExp(r'^(\d+) 月 (\d+) 日$').firstMatch(input)) != null) {
      return '${match!.group(1)}/${match.group(2)}';
    }
    if ((match = RegExp(r'^第 (\d+) / (\d+) 步$').firstMatch(input)) != null) {
      return 'Step ${match!.group(1)} of ${match.group(2)}';
    }
    if ((match = RegExp(r'^第 (\d+) / (\d+) 页$').firstMatch(input)) != null) {
      return 'Page ${match!.group(1)} of ${match.group(2)}';
    }
    if ((match = RegExp(r'^(\d+) / (\d+) 步$').firstMatch(input)) != null) {
      return '${match!.group(1)} / ${match.group(2)} steps';
    }
    if ((match = RegExp(r'^已完成 (\d+) 幅$').firstMatch(input)) != null) {
      return '${match!.group(1)} completed';
    }
    if ((match = RegExp(r'^继续第 (\d+) 步$').firstMatch(input)) != null) {
      return 'Continue step ${match!.group(1)}';
    }
    if ((match = RegExp(r'^我的画作 (\d+)$').firstMatch(input)) != null) {
      return 'My Artwork ${match!.group(1)}';
    }
    if ((match = RegExp(r'^⭐ (\d+) · 🔥 (\d+) 天$').firstMatch(input)) != null) {
      return '⭐ ${match!.group(1)} · 🔥 ${match.group(2)} days';
    }
    if (input.startsWith('作品详情 · ')) {
      return 'Artwork · ${translate(input.substring(7), locale)}';
    }
    if (input.startsWith('课程作品 · ')) {
      return 'Lesson Artwork · ${translate(input.substring(7), locale)}';
    }
    if (input.startsWith('涂色作品 · ')) {
      return 'Coloring · ${translate(input.substring(7), locale)}';
    }
    if (input.startsWith('跟着学画 · ')) {
      return 'Drawing Lesson · ${translate(input.substring(7), locale)}';
    }
    if (input.startsWith('继续画「') && input.endsWith('」')) {
      return 'Continue ${translate(input.substring(4, input.length - 1), locale)}';
    }
    if (input.startsWith('选择')) {
      return 'Choose ${translate(input.substring(2), locale)}';
    }
    if (input.startsWith('「') && input.contains('」已经保存到作品集')) {
      final end = input.indexOf('」');
      return '“${translate(input.substring(1, end), locale)}” was saved. You earned a star!';
    }
    if (input.startsWith('「') && input.endsWith('」删除后无法恢复。')) {
      final end = input.indexOf('」');
      return '“${translate(input.substring(1, end), locale)}” cannot be recovered after deletion.';
    }
    if (input.startsWith('已保存到作品集，约 ') && input.endsWith(' KB')) {
      return 'Saved to Gallery · ${input.substring(10)}';
    }
    if (input.startsWith('GIF 已保存：')) {
      return 'GIF saved: ${input.substring(7)}';
    }
    if (input.startsWith('已经完成 ') && input.endsWith(' 步，接着画吧！')) {
      final value = input.substring(5, input.length - 7);
      return '$value steps completed. Keep going!';
    }
    if (input.startsWith('已优先推荐 ') && input.endsWith(' 课程')) {
      final value = input.substring(6, input.length - 3);
      final parts = value.split(' · ');
      return 'Recommended: ${parts.map((part) => translate(part, locale)).join(' · ')}';
    }
    if (input.endsWith('完成')) {
      return 'Completed ${translate(input.substring(0, input.length - 2), locale)}';
    }
    if (input.contains(' · ')) {
      return input
          .split(' · ')
          .map((part) => translate(part, locale))
          .join(' · ');
    }
    return input;
  }

  static const _english = <String, String>{
    '小小画室 Little Art Studio': 'Little Art Studio',
    '首页': 'Home',
    '画画': 'Draw',
    '课程': 'Lessons',
    '作品集': 'Gallery',
    '动画': 'Animate',
    '家长': 'Parents',
    '家长中心': 'Parent Center',
    '你好，': 'Hello,',
    '米娅!': 'Mia!',
    '今天也要开心画画': 'Have fun drawing today',
    '今天想做什么？': 'What would you like to make?',
    '自由画画': 'Free Draw',
    '随心创作': 'Create anything',
    '涂色乐园': 'Coloring Garden',
    '放心涂，不出界': 'Color safely inside the lines',
    '跟着学画': 'Learn to Draw',
    '一步一步学': 'Learn step by step',
    '今日挑战': "Today's Challenge",
    '完成彩虹蝴蝶': 'Finish the rainbow butterfly',
    '今天已完成，明天再来': 'Completed today · Come back tomorrow',
    '今日创意任务': "Today's Creative Mission",
    '气球救援队': 'Balloon Rescue Team',
    '小兔子的气球飞到了高高的天空。': "The bunny's balloon has floated high into the sky.",
    '画一个神奇工具，帮小兔子把气球拿回来！':
        'Draw a magical tool to help the bunny get the balloon back!',
    '它可以很长、会飞，或者拥有魔法。': 'It can be very long, fly, or have magical powers.',
    '恐龙蛋的秘密': "The Dinosaur Egg's Secret",
    '咔嚓！一颗恐龙蛋裂开了一条缝。': 'Crack! A dinosaur egg has started to open.',
    '猜猜里面是谁，把它画出来吧！': 'Guess who is inside and draw them!',
    '也许是恐龙宝宝，也许是从没见过的新朋友。':
        'Maybe it is a baby dinosaur or a brand-new friend.',
    '神奇尾巴设计师': 'Magical Tail Designer',
    '小动物醒来，发现自己的尾巴不见了。':
        'A little animal wakes up and finds its tail is missing.',
    '给它设计一条独一无二的神奇尾巴！': 'Design a one-of-a-kind magical tail!',
    '尾巴可以像彩虹、火箭或者一朵花。':
        'The tail could look like a rainbow, a rocket, or a flower.',
    '三个圆变变变': 'Three Circles Transform',
    '画纸上滚来了三个圆，它们想变成不同的东西。':
        'Three circles roll onto the paper, ready to become different things.',
    '把三个圆分别变成三个有趣的新朋友！': 'Turn each circle into a different funny friend!',
    '加几笔，它们可以变成脸、星球或者食物。':
        'A few lines can turn them into faces, planets, or food.',
    '企鹅旅行车': "Penguin's Travel Machine",
    '小企鹅要去很远的地方参加冰雪派对。':
        'A little penguin is traveling far away to an ice party.',
    '为它设计一辆从没见过的交通工具！': 'Design a vehicle nobody has ever seen before!',
    '它可以有轮子、翅膀，也可以在水下前进。': 'It could have wheels, wings, or travel underwater.',
    '云朵里的朋友': 'Friend in the Clouds',
    '一朵云轻轻打开了门，里面传来笑声。': 'A cloud opens a tiny door, and laughter drifts out.',
    '画出住在云朵里的神秘朋友！': 'Draw the mysterious friend who lives in the cloud!',
    '它可能有很多只眼睛，也可能软绵绵的。': 'It might have many eyes or be soft and fluffy.',
    '另一半蝴蝶': "The Butterfly's Other Half",
    '蝴蝶的一边翅膀藏进了魔法森林。':
        "One of the butterfly's wings is hiding in the magic forest.",
    '画出另一边翅膀，也可以创造完全不同的花纹！':
        'Draw the other wing, with matching or totally new patterns!',
    '两边可以对称，也可以一边白天、一边夜晚。':
        'Make both sides match, or turn one into day and one into night.',
    '怪兽的新鞋': "The Monster's New Shoes",
    '圆滚滚的小怪兽想去跳舞，可它还没有脚。':
        'A round little monster wants to dance, but it has no feet yet.',
    '给怪兽画上有趣的腿和最酷的鞋子！':
        'Draw funny legs and the coolest shoes for the monster!',
    '腿的数量由你决定，鞋子也可以会发光。':
        'You choose how many legs it has. The shoes can even glow.',
    '海底小窗户': 'Little Underwater Window',
    '潜水艇的窗外闪过一个从没见过的影子。':
        'A mysterious shadow flashes past the submarine window.',
    '画出窗外的海底奇遇！': 'Draw the underwater adventure outside!',
    '可以加入发光的鱼、宝藏或海底城市。': 'Add glowing fish, treasure, or an underwater city.',
    '月亮上的家': 'A Home on the Moon',
    '月亮邀请你留下来过夜，可这里还没有房子。':
        'The moon invites you to stay, but there is no house yet.',
    '设计一座只属于月亮的奇妙小屋！': 'Design a wonderful little home made just for the moon!',
    '想想低重力的门、窗户和月亮床。': 'Imagine low-gravity doors, windows, and a moon bed.',
    '机器人的好朋友': "The Robot's Best Friend",
    '小机器人一个人坐在工作台上，有点孤单。':
        'A little robot sits alone at the workbench, feeling lonely.',
    '为它创造一个特别的新朋友！': 'Create a special new friend for it!',
    '朋友可以是动物、植物，也可以是一件物品。':
        'The friend can be an animal, plant, or even an object.',
    '树洞里的世界': 'The World Inside the Tree',
    '老树的树洞后面，竟然还有一扇小门。': 'Behind the old tree hollow is a tiny secret door.',
    '打开小门，画出藏在里面的世界！': 'Open the door and draw the hidden world inside!',
    '那里可以住着精灵，也可以是一座糖果城。':
        'Fairies might live there, or perhaps a whole candy city.',
    '太空宠物': 'Space Pet',
    '飞船收到一颗会蹦蹦跳跳的神秘信号。': 'The spaceship receives a mysterious bouncing signal.',
    '画出发出信号的可爱太空宠物！': 'Draw the cute space pet sending the signal!',
    '想想它有几只脚、吃什么、住在哪里。':
        'Imagine how many feet it has, what it eats, and where it lives.',
    '雨天变身派对': 'Rainy-Day Transformation Party',
    '雨滴落下来，地上的小水坑突然有了表情。':
        'Raindrops fall, and the puddles suddenly grow faces.',
    '把雨天变成一场热闹的变身派对！': 'Turn the rainy day into a lively transformation party!',
    '给雨滴加表情，再画雨伞、靴子或彩虹。':
        'Give raindrops faces, then add umbrellas, boots, or a rainbow.',
    '神奇任务卡': 'Magic Mission Card',
    '只能使用三种颜色': 'Use only three colors',
    '让画里出现一颗星星': 'Hide a star in the picture',
    '加入两个可爱贴纸': 'Add two cute stickers',
    '给主角戴上一顶帽子': 'Give the hero a hat',
    '画一个会飞的东西': 'Draw something that can fly',
    '藏进一个爱心图案': 'Hide a heart shape',
    '使用一次动物印章': 'Use an animal stamp once',
    '换一张': 'Draw Another Card',
    '虚线是故事开头，你画的线会保持实线': 'Dashed lines begin the story. Your lines stay solid.',
    '已恢复今天的挑战草稿': "Today's challenge draft was restored",
    '清空挑战画布吗？': 'Clear the challenge canvas?',
    '清空后还可以使用撤销找回来。': 'You can still bring it back with Undo.',
    '先画几笔，让故事继续吧！': 'Draw a few lines to continue the story!',
    '完成奖励：3 颗创意星星': 'Reward: 3 creativity stars',
    '再次完成可获得 1 颗星星': 'Complete again to earn 1 star',
    '完成挑战': 'Finish Challenge',
    '挑战作品': 'Challenge artwork',
    '挑战作品保存失败，请再试一次': 'Could not save the challenge artwork. Please try again.',
    '挑战完成，想象力大爆发！': 'Challenge complete. Imagination unleashed!',
    '挑战完成！': 'Challenge Complete!',
    '你的想象力让故事有了新的结局。': 'Your imagination gave the story a brand-new ending.',
    '作品已保存，获得 3 颗创意星星！': 'Artwork saved. You earned 3 creativity stars!',
    '作品已保存，获得 1 颗创意星星！': 'Artwork saved. You earned 1 creativity star!',
    '再挑战一次': 'Try Again',
    '返回首页': 'Back to Home',
    '我的作品集': 'My Gallery',
    '你的画作': 'Your creations',
    '动画故事': 'Animate Artwork',
    '让画动起来': 'Bring artwork to life',
    '动画小剧场': 'Animation Theater',
    '小小电影院': 'Little Cinema',
    '让你的画演一场故事': 'Let Your Artwork Star in a Story',
    '选演员、布舞台，再用手指亲自导演三幕动画。':
        'Choose an actor, set the stage, and direct a three-act animation with your finger.',
    '继续上次的小剧场': 'Continue Your Theater',
    '第一步 · 选择演员': 'Step 1 · Choose an Actor',
    '第二步 · 选择故事': 'Step 2 · Choose a Story',
    '小兔子寻找气球': 'Bunny Finds the Balloon',
    '追着风，飞过魔法森林': 'Follow the wind through the magic forest',
    '气球飞走了': 'The Balloon Flies Away',
    '让主角发现飞走的气球。': 'Let the hero discover the runaway balloon.',
    '勇敢去追': 'A Brave Chase',
    '拖着主角穿过森林，加入一个飞行动作。':
        'Drag the hero through the forest and add a flying action.',
    '找到啦': 'Found It!',
    '让主角跳起来接住气球，开心庆祝！': 'Make the hero jump, catch the balloon, and celebrate!',
    '恐龙宝宝第一次旅行': "Baby Dinosaur's First Trip",
    '从森林出发，认识新朋友': 'Leave the forest and meet a new friend',
    '背上小书包': 'Pack a Little Backpack',
    '让恐龙宝宝在家门口准备出发。': 'Get the baby dinosaur ready to leave home.',
    '越过小山坡': 'Over the Little Hill',
    '录下奔跑、跳跃和转圈的路线。': 'Record a path of running, jumping, and spinning.',
    '新朋友你好': 'Hello, New Friend',
    '安排一场见面舞会，留下快乐结局。': 'Direct a meeting dance and create a happy ending.',
    '企鹅的冰雪派对': "Penguin's Ice Party",
    '滑过海浪，赶上闪亮舞会': 'Ride the waves to a sparkling party',
    '派对邀请函': 'The Party Invitation',
    '让企鹅看到邀请函，惊喜地眨眨眼。':
        'Let the penguin see the invitation and blink with surprise.',
    '乘浪出发': 'Ride the Waves',
    '拖着企鹅滑过海浪，旋转躲开浪花。':
        'Drag the penguin over the waves and spin past the splashes.',
    '冰雪舞会': 'The Ice Dance',
    '设计一段跳跃舞蹈，为派对收尾。': 'Create a jumping dance to end the party.',
    '太空宠物回家': 'Space Pet Goes Home',
    '穿过星星，把小伙伴送回家': 'Travel through the stars to bring a friend home',
    '收到神秘信号': 'A Mysterious Signal',
    '让主角发现躲在星球后的太空宠物。': 'Let the hero find a space pet hiding behind a planet.',
    '星际飞行': 'Flight Through the Stars',
    '录制一条弯弯的飞行路线，避开星星。': 'Record a curving flight path around the stars.',
    '回到温暖的家': 'Back to a Warm Home',
    '用魔法闪光点亮家门，挥手告别。': 'Light the doorway with magic and wave goodbye.',
    '海底宝藏救援': 'Underwater Treasure Rescue',
    '潜入深海，帮助被困的小鱼': 'Dive deep to help a trapped little fish',
    '发现求救泡泡': 'Bubbles Calling for Help',
    '让主角跟着泡泡进入海底。': 'Let the hero follow the bubbles underwater.',
    '绕过珊瑚迷宫': 'Through the Coral Maze',
    '拖出曲折路线，加入旋转和眨眼。': 'Draw a winding route and add a spin and blink.',
    '宝藏变成礼物': 'Treasure Becomes a Gift',
    '救出小鱼，让宝箱发出魔法光芒。': 'Rescue the fish and make the treasure chest glow.',
    '怪兽生日惊喜': "Monster's Birthday Surprise",
    '偷偷准备一场城堡派对': 'Prepare a secret castle party',
    '准备秘密礼物': 'Prepare a Secret Gift',
    '让主角悄悄把礼物藏进城堡。': 'Let the hero quietly hide a gift inside the castle.',
    '怪兽要回来啦': 'The Monster Is Coming Back',
    '快速移动主角，布置最后的惊喜。': 'Move the hero quickly to finish the surprise.',
    '生日快乐': 'Happy Birthday',
    '跳起来、转圈圈，一起庆祝生日！': 'Jump, spin, and celebrate the birthday together!',
    '三幕故事卡': 'Three-Act Story Cards',
    '本地自动保存已开启': 'Local Autosave On',
    '选择舞台背景': 'Choose a Stage',
    '魔法森林': 'Magic Forest',
    '云朵天空': 'Cloudy Sky',
    '海底世界': 'Underwater World',
    '星际太空': 'Outer Space',
    '童话城堡': 'Fairytale Castle',
    '动作贴纸与音效': 'Action Stickers & Sounds',
    '转圈圈': 'Spin',
    '魔法闪光': 'Magic Sparkle',
    '点击开始表演，再用手指拖着演员走。':
        'Tap Start Performing, then drag the actor with your finger.',
    '正在录制：拖动演员，并点击动作贴纸！': 'Recording: drag the actor and tap action stickers!',
    '开始表演': 'Start Performing',
    '停止录制': 'Stop Recording',
    '表演录制中': 'Recording Performance',
    '先点击“开始表演”，再加入动作贴纸': 'Tap Start Performing before adding action stickers',
    '先录一段表演再回放吧！': 'Record a performance before playing it back!',
    '回放这一幕': 'Play This Act',
    '进入小小电影院': 'Open Little Cinema',
    '首映成功！': 'Premiere Complete!',
    '首映成功，掌声送给小导演！':
        'Premiere complete. A big round of applause for the director!',
    '获得 5 颗小导演星星！': 'You earned 5 little director stars!',
    '这部小剧场已经获得过导演奖励啦！':
        'This theater project has already earned its director reward!',
    '再放一遍': 'Play Again',
    '继续导演': 'Keep Directing',
    '最近画的': 'Recent Artwork',
    '查看全部': 'View All',
    '开心的太阳': 'Happy Sun',
    '我的小房子': 'My Little House',
    '打瞌睡的小猫': 'Sleepy Kitten',
    '月亮火箭': 'Moon Rocket',
    '今天': 'Today',
    '昨天': 'Yesterday',
    '刚刚': 'Just now',
    '上周': 'Last week',
    '自由创作': 'Free drawing',
    '示例作品': 'Sample artwork',
    '涂色作品': 'Coloring artwork',
    '课程作品': 'Lesson artwork',
    '画室示例': 'Studio sample',
    '我的创作': 'My creation',
    '自由画画、趣味涂色和分步课程，都可以离线使用。':
        'Free drawing, coloring, and step-by-step lessons all work offline.',
    '欢迎来到小小画室': 'Welcome to Little Art Studio',
    '每次创作都有惊喜': 'Every creation brings a surprise',
    '完成作品会获得创作星星，还能让自己的画跳舞、飞行和回放。':
        'Earn stars, then make your artwork jump, fly, and replay.',
    '专为孩子安心设计': 'Designed for children',
    '没有广告和外部链接；语音提示、年龄推荐都由家长管理。':
        'No ads or external links. Parents manage voice and recommendations.',
    '上一步': 'Back',
    '下一步': 'Next',
    '开始创作': 'Start Creating',
    '蜡笔': 'Crayon',
    '画笔': 'Marker',
    '水彩': 'Watercolor',
    '马克笔': 'Marker',
    '铅笔': 'Pencil',
    '闪光笔': 'Glow Pen',
    '橡皮': 'Eraser',
    '喷枪': 'Airbrush',
    '图案笔': 'Pattern Pen',
    '印章': 'Stamp',
    '贴纸': 'Sticker',
    '填色桶': 'Fill Bucket',
    '撤销': 'Undo',
    '重做': 'Redo',
    '清空': 'Clear',
    '清空画布': 'Clear Canvas',
    '保存预览': 'Save Artwork',
    '更新原作品': 'Update Artwork',
    '另存一份': 'Save a Copy',
    '复位画布': 'Reset Canvas',
    '背景层': 'Background',
    '绘画层': 'Drawing',
    '贴纸层': 'Stickers',
    '继续编辑原作品': 'Continue Editing',
    '已更新原作品': 'Artwork Updated',
    '自动保存已开启': 'Autosave On',
    '自动保存中…': 'Autosaving…',
    '已自动保存': 'Autosaved',
    '自动保存失败': 'Autosave Failed',
    '编辑中': 'Editing',
    '保存中…': 'Saving…',
    '正在保存…': 'Saving…',
    '保存中': 'Saving',
    '已保存到作品集': 'Saved to Gallery',
    '保存失败，请再试一次': 'Could not save. Please try again.',
    '保存失败，请检查设备存储空间': 'Could not save. Check device storage.',
    'PNG 已导出到相册': 'PNG exported to Photos',
    '先画一点东西再保存吧': 'Draw something before saving',
    '导出 PNG 到相册': 'Export PNG to Photos',
    '导出失败，请确认相册权限已开启': 'Export failed. Please allow photo access.',
    '搜索作品': 'Search artwork',
    '无法生成作品图片': 'Could not generate artwork image',
    '无法生成涂色作品': 'Could not generate coloring artwork',
    '已恢复上次自动保存的草稿': 'Your autosaved draft was restored',
    '清空这张画吗？': 'Clear this artwork?',
    '清空后还可以用“撤销”找回来。': 'You can still use Undo after clearing.',
    '继续画': 'Keep Drawing',
    '橙色': 'Orange',
    '黄色': 'Yellow',
    '绿色': 'Green',
    '蓝色': 'Blue',
    '紫色': 'Purple',
    '深棕色': 'Dark Brown',
    '彩虹蝴蝶': 'Rainbow Butterfly',
    '软萌小兔': 'Sweet Bunny',
    '草原小马': 'Meadow Pony',
    '圆滚企鹅': 'Round Penguin',
    '海底小鱼': 'Little Fish',
    '微笑花朵': 'Smiling Flower',
    '太空火箭': 'Space Rocket',
    '甜甜小猫': 'Sweet Kitten',
    '快乐小狗': 'Happy Puppy',
    '萌萌小恐龙': 'Cute Dinosaur',
    '慢慢小乌龟': 'Little Turtle',
    '智慧猫头鹰': 'Wise Owl',
    '喷水小鲸鱼': 'Splashing Whale',
    '幸运小瓢虫': 'Lucky Ladybug',
    '散步小蜗牛': 'Strolling Snail',
    '选颜色': 'Choose a Color',
    '太棒啦！': 'Wonderful!',
    '继续创作': 'Keep Creating',
    '保存到作品集': 'Save to Gallery',
    '完成作品': 'Finish Artwork',
    '从一笔开始，画出大世界': 'A big world begins with one line',
    '挑一幅喜欢的作品，我们一步一步来。': 'Choose an artwork and draw it one step at a time.',
    '挑一幅开始吧': 'Choose a lesson',
    '开始第一课': 'Start First Lesson',
    '开始画画': 'Start Drawing',
    '完成课程': 'Finish Lesson',
    '返回课程': 'Back to Lessons',
    '再画一次': 'Draw Again',
    '画好啦！': 'You Did It!',
    '每一笔都很特别，作品已经自动保存到作品集啦！':
        'Every line is special. Your artwork was saved to the Gallery!',
    '课程已经完成，但作品保存失败，请检查设备存储空间。':
        'Lesson complete, but saving failed. Check device storage.',
    '显示提示': 'Show Guide',
    '朗读本步骤': 'Read This Step',
    '未开始': 'Not Started',
    '已完成': 'Completed',
    '全部': 'All',
    '可爱动物': 'Cute Animals',
    '恐龙世界': 'Dinosaurs',
    '交通工具': 'Vehicles',
    '节日快乐': 'Celebrations',
    '入门': 'Beginner',
    '进阶': 'Intermediate',
    '挑战': 'Challenge',
    '3-5岁': 'Ages 3–5',
    '2-4岁': 'Ages 2–4',
    '4-6岁': 'Ages 4–6',
    '6-8岁': 'Ages 6–8',
    '9-12岁': 'Ages 9–12',
    '约 6 分钟': 'About 6 min',
    '约 7 分钟': 'About 7 min',
    '约 8 分钟': 'About 8 min',
    '圆脸小猫': 'Round-Faced Kitten',
    '用圆形和三角形画一只萌萌的小猫': 'Draw a cute kitten with circles and triangles',
    '月光窗台音乐会': 'Moonlit Windowsill Concert',
    '今晚窗台上有一场很小很小的音乐会，圆脸小猫想第一个登台。':
        'Tonight there is a tiny concert on the windowsill, and the round-faced kitten wants to go first.',
    '帮小猫准备好圆圆的脸、软软的耳朵和开心的笑容。':
        'Help the kitten get a round face, soft ears, and a happy smile.',
    '小猫登台啦': 'The Kitten Takes the Stage',
    '月光落在窗台上，小猫带着你画出的笑脸唱起了第一首歌。':
        'Moonlight lands on the windowsill, and the kitten sings the first song with the smile you drew.',
    '画一个大圆': 'Draw a Big Circle',
    '先画一个大大的圆，做小猫的脑袋。': "Draw a large circle for the kitten's head.",
    '慢慢转动手腕，圆不需要特别完美。':
        "Move your wrist slowly. It doesn't need to be perfect.",
    '小猫从月光里探出圆圆的脑袋。': 'The kitten peeks a round head out of the moonlight.',
    '画室伙伴点点头：这个圆像一颗暖暖的小月亮。':
        'The studio buddy nods: this circle feels like a warm little moon.',
    '添上三角耳朵': 'Add Triangle Ears',
    '在圆形上方画两个小三角形。': 'Draw two small triangles above the circle.',
    '两只耳朵一高一低也很可爱。': 'Uneven ears can be cute too.',
    '小猫竖起耳朵，听见远处的铃声。': 'The kitten lifts its ears and hears bells far away.',
    '太好了，小猫已经听见音乐会开始的声音。':
        'Wonderful, the kitten can hear the concert beginning.',
    '画弯弯的眼睛': 'Draw Curved Eyes',
    '加上眼睛和一个小鼻子。': 'Add eyes and a tiny nose.',
    '像画两个月牙一样画眼睛。': 'Draw the eyes like two little moons.',
    '它眯起眼睛，准备唱第一句。':
        'It smiles with curved eyes, ready to sing the first line.',
    '这双眼睛真温柔，故事开始有表情了。': 'Those eyes are gentle. The story has expression now.',
    '加上笑脸和胡须': 'Add a Smile and Whiskers',
    '最后画嘴巴和三根长胡须。': 'Finish with a mouth and three long whiskers.',
    '选喜欢的颜色，再加一点腮红吧。': 'Choose a color and add rosy cheeks.',
    '胡须轻轻摆动，小猫向观众鞠躬。':
        'The whiskers sway softly as the kitten bows to the audience.',
    '完成啦，小猫已经准备好登上窗台。':
        'Done. The kitten is ready to step onto the windowsill.',
    '快乐小恐龙': 'Happy Little Dinosaur',
    '从椭圆开始，画一只温柔的小恐龙': 'Start with an oval to draw a gentle dinosaur',
    '小恐龙去找星星': 'The Little Dinosaur Looks for a Star',
    '山谷黑下来以后，小恐龙听说有一颗星星掉在了草地上。':
        'After the valley grows dark, the little dinosaur hears that a star has fallen into the grass.',
    '陪它长出身体、脖子、脚步和勇敢的笑脸，一起出发找星星。':
        'Give it a body, neck, footsteps, and brave smile so you can look for the star together.',
    '星星被找到了': 'The Star Is Found',
    '小恐龙抬头一看，原来最亮的星星就藏在你的画里。':
        'The little dinosaur looks up and finds the brightest star hiding inside your drawing.',
    '画椭圆身体': 'Draw an Oval Body',
    '横着画一个胖胖的椭圆。': 'Draw a wide, plump oval.',
    '椭圆越饱满，小恐龙越可爱。': 'A fuller oval makes a cuter dinosaur.',
    '小恐龙背起小包，圆圆的身体装满勇气。':
        'The little dinosaur packs a tiny bag, its round body full of courage.',
    '这一步很稳，小恐龙已经站在故事开头了。':
        'That step is steady. The dinosaur is standing at the start of the story.',
    '加上脑袋和脖子': 'Add Head and Neck',
    '从身体向上画长脖子和小脑袋。': 'Draw a long neck and small head above the body.',
    '用一条柔软的弧线连接身体。': 'Connect it with a gentle curve.',
    '它伸长脖子，想看见草地尽头的星光。':
        'It stretches its neck to see the starlight beyond the grass.',
    '好棒，这条弧线让小恐龙真的抬起头了。': 'Lovely. That curve really lifts the dinosaur head.',
    '添四条腿和尾巴': 'Add Legs and Tail',
    '画短短的腿，再加一条长尾巴。': 'Draw short legs and a long tail.',
    '脚掌可以画成圆圆的小方块。': 'Make the feet soft, rounded squares.',
    '四只小脚踩过草叶，尾巴轻轻保持平衡。':
        'Four little feet step through the grass while the tail keeps balance.',
    '现在它可以出发了，每一步都很勇敢。': 'Now it can set off. Every step feels brave.',
    '画背刺和表情': 'Add Spikes and a Face',
    '沿背部加三角背刺，再画笑脸。': 'Add triangle spikes and a happy face.',
    '背刺可以大小不一样。': 'The spikes can be different sizes.',
    '它笑着发现：星星正在前方闪呀闪。': 'It smiles and sees the star twinkling ahead.',
    '故事亮起来了，小恐龙看见星星了。':
        'The story lights up. The little dinosaur sees the star.',
    '出发吧小汽车': 'Little Car Adventure',
    '组合方形和圆形，画自己的小汽车': 'Combine rectangles and circles to draw a car',
    '彩虹信件快快送': 'Deliver the Rainbow Letter',
    '清晨的小路上，有一封彩虹信要送到山坡另一边。':
        'On a morning road, a rainbow letter needs to reach the other side of the hill.',
    '画出车身、车顶、轮子和灯光，让小汽车把惊喜送到朋友手里。':
        'Draw the body, roof, wheels, and lights so the little car can deliver a surprise.',
    '彩虹信送到啦': 'The Rainbow Letter Arrives',
    '小汽车按响轻轻的喇叭，朋友打开信，彩虹从纸里跑了出来。':
        'The little car gives a soft beep, a friend opens the letter, and a rainbow runs out of the paper.',
    '画长方形车身': 'Draw the Car Body',
    '先画一个圆角长方形。': 'Start with a rounded rectangle.',
    '车头可以稍微高一点。': 'Make the front a little taller.',
    '小汽车把彩虹信放进车厢，准备出发。':
        'The little car puts the rainbow letter inside and gets ready to leave.',
    '车身画好了，彩虹信有地方坐了。':
        'The body is ready. The rainbow letter has a place to ride.',
    '加上车顶': 'Add the Roof',
    '在车身上画一个梯形车顶。': 'Draw a trapezoid roof above the body.',
    '给车顶留出两扇窗的位置。': 'Leave room for two windows.',
    '车顶挡住晨雾，窗户看见弯弯的小路。':
        'The roof blocks the morning mist, and the windows see the winding road.',
    '这个车顶很可靠，旅程不怕小雨了。':
        'That roof is reliable. The trip is ready for a little rain.',
    '画两个轮子': 'Draw Two Wheels',
    '在车身下方画两个圆形轮子。': 'Draw two round wheels below the body.',
    '让两个轮子差不多大。': 'Try to make the wheels similar in size.',
    '轮子转起来，石子路也变成节奏。': 'The wheels turn, and the pebbly road becomes a rhythm.',
    '出发！两个轮子正在带故事往前走。': 'Off we go. Two wheels are carrying the story forward.',
    '装饰车窗和车灯': 'Decorate Windows and Lights',
    '画上车窗、车灯和喜欢的花纹。': 'Add windows, lights, and favorite patterns.',
    '给小汽车取一个名字吧。': 'Give your car a name.',
    '车灯亮起，彩虹信马上就要送到。':
        'The headlights turn on. The rainbow letter is almost there.',
    '小汽车有了自己的性格，像真正的故事主角。':
        'The little car has its own personality, like a true story hero.',
    '圆圆红灯笼': 'Round Red Lantern',
    '用弧线画一个喜气洋洋的小灯笼': 'Use curves to draw a festive lantern',
    '点亮节日夜': 'Light the Festival Night',
    '节日夜的街角有一点暗，小画室伙伴想挂起一盏会讲故事的灯笼。':
        'One corner of the festival night is a little dark, so the studio buddy wants to hang a lantern that tells stories.',
    '用弧线、提绳、流苏和花纹，把夜晚一点一点照亮。':
        'Use curves, a string, tassels, and patterns to light the night bit by bit.',
    '灯笼讲起故事': 'The Lantern Begins Its Story',
    '灯笼亮了起来，街角的人都停下脚步，看见光里有你的线条。':
        'The lantern glows, and everyone at the corner stops to see your lines inside the light.',
    '画灯笼肚子': 'Draw the Lantern Body',
    '画一个竖着的胖椭圆。': 'Draw a tall, plump oval.',
    '上下稍窄，中间圆鼓鼓。': 'Keep the top and bottom narrow and the middle round.',
    '灯笼先有了一个能装下光的肚子。':
        'First the lantern gets a belly big enough to hold light.',
    '这个形状很饱满，里面好像已经有一点亮了。':
        'That shape is full. It already feels a little bright inside.',
    '加上顶盖和底座': 'Add Top and Base',
    '在椭圆上下各画一个小长方形。': 'Draw a small rectangle above and below the oval.',
    '让顶盖和底座对齐。': 'Line up the top and base.',
    '顶盖轻轻扣上，光就不会跑丢。': 'The top closes gently so the light will not slip away.',
    '结构站稳了，这盏灯笼可以被挂起来。':
        'The structure is steady. This lantern can be hung up now.',
    '画提绳和流苏': 'Draw the String and Tassels',
    '上面添提绳，下面添长流苏。': 'Add a string above and long tassels below.',
    '流苏可以画得轻轻摆动。': 'Let the tassels sway gently.',
    '晚风一吹，流苏开始替灯笼跳舞。':
        'When the evening wind blows, the tassels dance for the lantern.',
    '流苏让画面动起来了，像一页真正的绘本。':
        'The tassels make the picture move, like a real storybook page.',
    '加花纹和光芒': 'Add Patterns and Sparkles',
    '在灯笼上画弧线，再添几颗小星星。': 'Add curved patterns and a few stars.',
    '最后涂上最喜庆的颜色。': 'Finish with your most festive colors.',
    '花纹亮起，整条街都看见了温暖的光。':
        'The patterns glow, and the whole street sees warm light.',
    '完成啦，你把节日夜点亮了。': 'Finished. You lit up the festival night.',
    '故事页已经保存到作品集': 'The story page was saved to the Gallery',
    '故事完成了，但作品保存失败，请检查设备存储空间。':
        'The story is complete, but saving failed. Check device storage.',
    '米娅的小画展': "Mia's Art Show",
    '每一幅画，都是独一无二的小故事。': 'Every artwork tells a unique little story.',
    '最近': 'Recent',
    '收藏': 'Favorites',
    '还没有收藏作品': 'No Favorites Yet',
    '作品集还是空的': 'Your Gallery Is Empty',
    '看到喜欢的作品，就点亮右上角的爱心。': 'Tap the heart on artwork you love.',
    '去画板完成第一幅作品吧！': 'Create your first artwork!',
    '画一幅新的': 'Create New Artwork',
    '取消收藏': 'Remove Favorite',
    '收藏作品': 'Favorite Artwork',
    '作品信息': 'Artwork Details',
    '完成时间': 'Completed',
    '创作工具': 'Creation Mode',
    '画布形式': 'Canvas',
    '横屏画布': 'Landscape Canvas',
    '每一次创作都值得被好好收藏。给喜欢的作品点一颗爱心吧！':
        'Every creation is worth keeping. Tap the heart on your favorites!',
    '再画一幅': 'Draw Another',
    '重命名': 'Rename',
    '删除': 'Delete',
    '给作品换个名字': 'Rename Artwork',
    '作品名称': 'Artwork Name',
    '保存名字': 'Save Name',
    '取消': 'Cancel',
    '删除这幅作品吗？': 'Delete This Artwork?',
    '保留作品': 'Keep Artwork',
    '确认删除': 'Delete',
    '选一幅画': 'Choose Artwork',
    '选择一幅作品': 'Choose an Artwork',
    '选择动画': 'Choose an Animation',
    '轻轻呼吸': 'Gentle Breathing',
    '跳一跳': 'Jump',
    '眨眼': 'Blink',
    '飞起来': 'Fly',
    '笔画回放': 'Stroke Replay',
    '星星贴纸': 'Star Sticker',
    '月亮贴纸': 'Moon Sticker',
    '彩虹贴纸': 'Rainbow Sticker',
    '小花贴纸': 'Flower Sticker',
    '我的故事从第一笔开始': 'My story begins with the first line',
    '画里的朋友轻轻动了起来': 'The friend in the picture gently comes alive',
    '最后一页，把想象留在星光里': 'On the last page, imagination stays in the starlight',
    '我的故事已经生成': 'My story has been created',
    '多页绘本故事板': 'Multi-page Storyboard',
    '第 1 页': 'Page 1',
    '第 2 页': 'Page 2',
    '第 3 页': 'Page 3',
    '贴纸和字幕': 'Stickers & Captions',
    '显示字幕': 'Show Captions',
    '轻柔背景音乐': 'Gentle Background Music',
    '播放时使用克制的声音提示': 'Use quiet sound cues while playing',
    '轻柔背景音乐已开启': 'Gentle background music is on',
    '一键生成我的故事': 'Create My Story',
    '保存 GIF': 'Save GIF',
    '正在导出 GIF…': 'Exporting GIF…',
    'GIF 导出失败，请再试一次': 'GIF export failed. Please try again.',
    '保存 MP4': 'Save MP4',
    'MP4 导出需要接入原生视频编码器，本版已准备故事板和 GIF 导出':
        'MP4 export needs a native video encoder. This version has storyboard and GIF export ready.',
    '暂停动画': 'Pause Animation',
    '播放动画': 'Play Animation',
    '请家长回答': 'For Parents',
    '12 + 7 等于多少？': 'What is 12 + 7?',
    '答案不对，请再想一想': 'Not quite. Please try again.',
    '累计使用': 'Total Time',
    '不足 1 分钟': 'Less than 1 min',
    '孩子作品': 'Child Artwork',
    '课程完成数': 'Lessons Completed',
    '语音提示与音效': 'Voice Prompts & Sounds',
    '课程朗读、点击声和完成鼓励': 'Lesson narration, taps, and encouragement',
    '显示语言': 'Display Language',
    '跟随系统': 'Follow System',
    '简体中文': '简体中文',
    '推荐年龄': 'Recommended Age',
    '课程难度': 'Lesson Difficulty',
    '太棒啦，完成得真好！': 'Wonderful! You did a great job!',
  };
}

extension StudioLocalizationContext on BuildContext {
  String tr(String input) =>
      StudioLocalizations.translate(input, Localizations.localeOf(this));

  String get languageToggleLabel =>
      Localizations.localeOf(this).languageCode == 'zh' ? 'EN' : '中文';
}

class LocalizedText extends StatelessWidget {
  const LocalizedText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) => Text(
    context.tr(data),
    style: style,
    strutStyle: strutStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    locale: locale,
    softWrap: softWrap,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel == null ? null : context.tr(semanticsLabel!),
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    selectionColor: selectionColor,
  );
}
