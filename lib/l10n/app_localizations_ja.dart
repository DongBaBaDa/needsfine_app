// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get category => 'カテゴリ';

  @override
  String get koreanFood => '韓国料理';

  @override
  String get japaneseFood => '和食';

  @override
  String get chineseFood => '中華';

  @override
  String get westernFood => '洋食';

  @override
  String get cafe => 'カフェ';

  @override
  String get dessert => 'デザート';

  @override
  String get fastFood => 'ファストフード';

  @override
  String get snackFood => '軽食';

  @override
  String get weeklyRanking => '週間ランク';

  @override
  String get more => 'もっと見る';

  @override
  String get needsFine => 'NeedsFine';

  @override
  String get appName => 'NeedsFine';

  @override
  String get appTagline => '本物が必要';

  @override
  String get appSubtitle => '体験とデータの出会う場所';

  @override
  String get emailLoginButton => 'メールでログイン';

  @override
  String get emailSignupButton => 'メールで新規登録';

  @override
  String get reliability => '信頼度';

  @override
  String get reviewRanking => 'レビューランク';

  @override
  String get totalReviews => 'レビュー数';

  @override
  String get avgNeedsFineScore => '平均NFスコア';

  @override
  String get needsFineScore => 'NFスコア';

  @override
  String get avgReliability => '平均信頼度';

  @override
  String get reviewList => 'レビュー一覧';

  @override
  String get comments => 'コメント';

  @override
  String get storeRanking => '店舗ランク';

  @override
  String get sortByScore => 'NFスコア順';

  @override
  String get sortByReliability => '信頼度順';

  @override
  String get bitterCriticism => '辛口';

  @override
  String get latestOrder => '新着順';

  @override
  String get noInfo => '情報なし';

  @override
  String get follow => 'フォロー';

  @override
  String get follower => 'フォロワー';

  @override
  String get following => 'フォロー中';

  @override
  String get review => 'レビュー';

  @override
  String get noListGenerated => 'リストがありません';

  @override
  String get highScore => '高得点';

  @override
  String userListTitle(Object username) {
    return '$usernameのリスト';
  }

  @override
  String get sortByUserRating => '評価順';

  @override
  String get sortByReviewCount => 'レビュー数順';

  @override
  String get home => 'ホーム';

  @override
  String get mySurroundings => '周辺';

  @override
  String get myFine => 'マイ';

  @override
  String get searchStore => '検索';

  @override
  String get editProfile => 'プロフィール編集';

  @override
  String get myFeed => 'マイフィード';

  @override
  String get reviewCollection => '保存済み';

  @override
  String get myOwnList => 'マイリスト';

  @override
  String get myTaste => 'マイテイスト';

  @override
  String get customerCenter => 'ヘルプ';

  @override
  String get notice => 'お知らせ';

  @override
  String get notifications => '通知';

  @override
  String get newComment => '新しいコメント';

  @override
  String get reviewHelpful => '参考になった';

  @override
  String get newNotice => '新着お知らせ';

  @override
  String get settings => '設定';

  @override
  String get phoneNumber => '電話番号';

  @override
  String get verificationNeeded => '認証';

  @override
  String get email => 'メール';

  @override
  String get gender => '性別';

  @override
  String get unspecified => '未設定';

  @override
  String get languageSettings => '言語設定';

  @override
  String get changePassword => 'パスワード変更';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get termsOfService => '利用規約';

  @override
  String get logout => 'ログアウト';

  @override
  String get currentVersion => 'バージョン';

  @override
  String get deleteAccount => '退会';

  @override
  String get sendSuggestion => 'ご意見';

  @override
  String get inquiry => 'お問い合わせ';

  @override
  String get accountInfo => 'アカウント';

  @override
  String get general => '一般';

  @override
  String get securityAndNotifications => 'セキュリティ';

  @override
  String get info => '情報';

  @override
  String get apply => '適用';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => 'OK';

  @override
  String get developingMessage => '準備中です';

  @override
  String get noName => '名前なし';

  @override
  String get noIntro => '紹介文なし';

  @override
  String get loadError => 'エラー';

  @override
  String get adminMenu => '管理者';

  @override
  String get whatIsScore => 'NFスコアとは?';

  @override
  String get scoreDesc => 'ユーザーレビューから店舗の雰囲気を数値化したスコア';

  @override
  String get waitingSpot => '人気店';

  @override
  String get localSpot => '地元の名店';

  @override
  String get goodSpot => 'おすすめ';

  @override
  String get polarizingSpot => '好み分かれる';

  @override
  String get whatIsReliability => '信頼度とは?';

  @override
  String get reliabilityDesc => 'レビューの信頼性パーセント';

  @override
  String get movingToMap => 'マップへ移動';

  @override
  String get noNewNotifications => '新着通知なし';

  @override
  String get checkReview => 'レビューを見る';

  @override
  String get viewAllNotices => '全てのお知らせ';

  @override
  String get deletedReview => '削除されたレビュー';

  @override
  String get deletedComment => '削除されたコメント';

  @override
  String get unknownUser => '不明';

  @override
  String get loading => '読み込み中...';

  @override
  String followNotification(Object name) {
    return '$nameさんがフォロー';
  }

  @override
  String startFollowingMessage(Object name) {
    return '$nameさんをフォロー';
  }

  @override
  String unfollowMessage(Object name) {
    return '$nameさんのフォロー解除';
  }

  @override
  String get emailLogin => 'メールログイン';

  @override
  String get welcomeBack => 'おかえりなさい!\nメールでログインしてください。';

  @override
  String get emailAddress => 'メールアドレス';

  @override
  String get emailPlaceholder => 'example@email.com';

  @override
  String get password => 'パスワード';

  @override
  String get loginButton => 'ログイン';

  @override
  String get loginRequired => 'メールとパスワードを入力';

  @override
  String get invalidCredentials => 'メールまたはパスワードが違います';

  @override
  String get serverError => '接続に失敗しました';

  @override
  String get loginInfoError => 'ログイン情報が正しくありません';

  @override
  String get savedStores => '保存済み';

  @override
  String get allSavedStores => 'お気に入りの店舗';

  @override
  String get myListsTab => 'マイリスト';

  @override
  String get sharedListsTab => '共有中';

  @override
  String get noListsYet => 'リストがありません\n作成してみましょう!';

  @override
  String get noSharedLists => '共有リストなし';

  @override
  String get createList => 'リスト作成';

  @override
  String get newListTitle => '新規リスト';

  @override
  String get newListHint => 'リストに店舗を追加できます';

  @override
  String get listNamePlaceholder => '例: デート、ランチ';

  @override
  String get createButton => '作成';

  @override
  String get tapToAddStores => 'タップして店舗を追加';

  @override
  String get deleteList => '削除';

  @override
  String get shareList => '共有';

  @override
  String get makePrivate => '非公開に';

  @override
  String get deleteListConfirm => 'リスト削除';

  @override
  String deleteListMessage(Object listName) {
    return '\"$listName\"を削除しますか?\n全ての項目が削除されます。';
  }

  @override
  String get listDeleted => 'リスト削除済み';

  @override
  String get listShared => 'リスト共有済み';

  @override
  String get listPrivate => 'リスト非公開に';

  @override
  String get deleteFailed => '削除に失敗';

  @override
  String get settingFailed => '設定に失敗';

  @override
  String get listCreated => 'リスト作成完了!';

  @override
  String itemCount(Object count) {
    return '$count件';
  }

  @override
  String get addStores => '店舗追加';

  @override
  String get noStoresInList => 'リストが空です\n+をタップして追加';

  @override
  String get alreadyAdded => '追加済み';

  @override
  String get addToList => '追加';

  @override
  String get addedToList => 'リストに追加しました';

  @override
  String get removeFromList => '削除';

  @override
  String get signup => '新規登録';

  @override
  String get searchPlaceholder => '店舗・地域・キーワード検索';

  @override
  String get realTimeBestReviews => 'ベストレビュー 🏆';

  @override
  String get imagePreparing => '画像読込中...';

  @override
  String get rank => '位';

  @override
  String get trustScore => '信頼度';

  @override
  String get passwordRequirement => '8文字以上、大小文字、特殊文字含む';

  @override
  String get passwordValid => 'パスワードOK';

  @override
  String get passwordMatch => 'パスワード一致';

  @override
  String get passwordMismatch => 'パスワード不一致';

  @override
  String get signupFailed => '登録失敗';

  @override
  String get myActivity => 'アクティビティ';

  @override
  String get customerSupport => 'サポート';

  @override
  String get noImages => '画像なし';

  @override
  String get invalidEmail => '有効なメールを入力';

  @override
  String get authCodeSent => '認証コードを送信しました';

  @override
  String sendFailed(Object error) {
    return '送信失敗: $error';
  }

  @override
  String get invalidAuthCodeLength => '6桁のコードを入力';

  @override
  String get emailVerified => 'メール認証完了';

  @override
  String get verificationFailed => '認証失敗';

  @override
  String get invalidAuthCode => 'コードが無効または期限切れ';

  @override
  String get nicknameRequired => 'ニックネームを入力';

  @override
  String signupError(Object error) {
    return 'エラー: $error';
  }

  @override
  String get sessionExpired => 'セッション切れ。再試行してください';

  @override
  String get emailAutoVerified => 'メール自動認証完了';

  @override
  String get enterEmail => 'メールアドレスを入力';

  @override
  String get emailUsageInfo => 'ログインとアカウント復旧に使用';

  @override
  String get authCode => '6桁コード';

  @override
  String get requestAuth => '認証';

  @override
  String get resend => '再送信';

  @override
  String get next => '次へ';

  @override
  String get setPassword => 'パスワード設定';

  @override
  String get passwordHint => '8文字以上、英数字、特殊文字含む';

  @override
  String get enterPassword => 'パスワード入力';

  @override
  String get confirmPassword => 'パスワード確認';

  @override
  String get reenterPassword => 'パスワード再入力';

  @override
  String get whereDoYouLive => 'お住まいの地域は?';

  @override
  String get regionInfo => '地域のおすすめに必要です';

  @override
  String get city => '都道府県';

  @override
  String get district => '市区町村';

  @override
  String get setNickname => 'ニックネームを決める';

  @override
  String get nicknameInfo => '後から変更できます';

  @override
  String get nickname => 'ニックネーム';

  @override
  String get nicknameHint => '2~10文字、英数字';

  @override
  String get checkDuplicate => '確認';

  @override
  String get nicknameEmpty => 'ニックネームを入力';

  @override
  String get nicknameTooShort => '2文字以上必要';

  @override
  String get nicknameDuplicate => '使用済みのニックネーム';

  @override
  String get nicknameAvailable => '使用可能なニックネーム';

  @override
  String get completeSignup => '完了';

  @override
  String get welcome => 'ようこそ!';

  @override
  String get signupCompleteMessage => '登録完了しました';

  @override
  String get getStarted => '始める';
}
