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
    '我的作品集': 'My Gallery',
    '你的画作': 'Your creations',
    '动画故事': 'Animate Artwork',
    '让画动起来': 'Bring artwork to life',
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
    '跳一跳': 'Jump',
    '眨眼': 'Blink',
    '飞起来': 'Fly',
    '笔画回放': 'Stroke Replay',
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
