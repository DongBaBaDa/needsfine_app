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
  String get sortByDistance => '거리순';

  @override
  String distanceUnit(Object distance) {
    return '${distance}km';
  }

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
  String get loading => '読み込み中...';

  @override
  String followNotification(Object name) {
    return '$nameさんがフォロー';
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

  @override
  String get feed => '피드';

  @override
  String get birthDate => '생년월일';

  @override
  String get birthDateSet => '생년월일 설정';

  @override
  String get blockedUserManagement => '차단한 사용자 관리';

  @override
  String get communityGuidelines => '커뮤니티 가이드라인';

  @override
  String get communityGuidelinesContent => '커뮤니티 가이드라인 내용';

  @override
  String get genderSet => '성별 설정';

  @override
  String get myTasteSummary => '내 취향 요약';

  @override
  String get analyzeAgain => '다시 분석하기';

  @override
  String get adminDashboard => '관리자 대시보드';

  @override
  String get bannerManagement => '배너 관리';

  @override
  String get reportManagement => '신고 관리';

  @override
  String get recalculateReviews => '리뷰 점수 재산정';

  @override
  String get myReviews => '내가 쓴 리뷰';

  @override
  String get helpfulReviews => '도움이 됐어요';

  @override
  String get commentedReviews => '댓글 단 리뷰';

  @override
  String get noReviewsWritten => '작성한 리뷰가 없습니다.';

  @override
  String get experienceQuestion => '어떤 점이 좋았나요?';

  @override
  String get chooseFeatures => '매장의 특징을 선택해주세요.';

  @override
  String get findRestaurant => '방문한 맛집을 찾아주세요';

  @override
  String get submitReview => '리뷰 등록';

  @override
  String get editComplete => '수정 완료';

  @override
  String get locationNotFound => '위치를 찾을 수 없습니다.';

  @override
  String get saveError => '저장 중 오류가 발생했습니다.';

  @override
  String get calculating => '계산 중...';

  @override
  String get markAllRead => '모두 읽음처리';

  @override
  String get noNotifications => '새로운 알림이 없습니다.';

  @override
  String notificationComment(Object name) {
    return '$name님이 회원님의 리뷰에 댓글을 남겼습니다.';
  }

  @override
  String notificationHelpful(Object name) {
    return '$name님이 회원님의 리뷰를 좋아합니다.';
  }

  @override
  String get editNotice => '공지사항 수정';

  @override
  String get title => '제목';

  @override
  String get content => '내용';

  @override
  String get enterTitle => '제목을 입력하세요';

  @override
  String get male => '남성';

  @override
  String get female => '여성';

  @override
  String get genderOneTime => '성별은 한 번만 설정할 수 있습니다.';

  @override
  String get birthDateOneTime => '생년월일은 한 번만 설정할 수 있습니다.';

  @override
  String get birthDateSelect => '생년월일 선택 (한 번만 설정 가능)';

  @override
  String get saved => '저장되었습니다.';

  @override
  String get unblock => '해제';

  @override
  String get noBlockedUsers => '차단한 사용자가 없습니다.';

  @override
  String get noLikedReviews => '도움이 됐어요 표시한 리뷰가 없습니다.';

  @override
  String get noCommentedReviews => '댓글을 작성한 리뷰가 없습니다.';

  @override
  String get addFailed => '추가에 실패했습니다.';

  @override
  String get noSavedStores => '저장한 매장이 없습니다.';

  @override
  String get noReviewsForStore => '추가할 수 있는 리뷰가 없는 매장입니다.';

  @override
  String get addSavedStore => '저장한 매장 추가';

  @override
  String get added => '추가됨';

  @override
  String get selectItemsToAdd => '추가할 항목을 선택하세요';

  @override
  String addNItems(Object count) {
    return '$count개 추가하기';
  }

  @override
  String get emptyListHint => '아직 리스트에 담긴 매장이 없습니다.\n우측 상단 +로 저장한 매장을 추가해보세요.';

  @override
  String get noSavedStoresHint => '저장한 매장이 없습니다.\n마음에 드는 매장을 저장해보세요!';

  @override
  String get tasteSurveyTitle => '당신은 뭘 좋아하나요?';

  @override
  String get tasteSurveySubtitle => '취향을 알려주시면 딱 맞는 맛집을 추천해드려요.\n(30초면 충분해요!)';

  @override
  String get doItLater => '나중에 하기';

  @override
  String get start => '시작하기';

  @override
  String get tasteKorean => '한식 파';

  @override
  String get tasteChinese => '중식 러버';

  @override
  String get tasteJapanese => '일식 매니아';

  @override
  String get tasteWestern => '양식 선호';

  @override
  String get tasteSpicyLover => '매운맛 고수';

  @override
  String get tasteSpicyHater => '맵찔이';

  @override
  String get tasteCostEffective => '가성비 중시';

  @override
  String get tasteAtmosphere => '분위기 깡패';

  @override
  String get tasteSolo => '혼밥족';

  @override
  String get tasteDate => '데이트 맛집';

  @override
  String get tasteDessert => '디저트 필수';

  @override
  String get tasteOldGen => '노포 감성';

  @override
  String get loadFailed => '정보를 불러오지 못했습니다.';

  @override
  String get noNotices => '아직 등록된 공지사항이 없어요.';

  @override
  String get noFollowers => '아직 팔로워가 없습니다.';

  @override
  String get noFollowings => '팔로잉하는 유저가 없습니다.';

  @override
  String followMessage(Object nickname) {
    return '$nicknameをフォロー';
  }

  @override
  String get errorOccurred => '오류가 발생했습니다.';

  @override
  String get unknownUser => '不明';

  @override
  String get reviewCount => '리뷰';

  @override
  String get followerCount => '팔로워';

  @override
  String get followingCount => '팔로잉';

  @override
  String get noIntroduction => '소개글이 없습니다.';

  @override
  String get tasteAnalysis => '취향 분석';

  @override
  String get scoreDistribution => '평점 분포';

  @override
  String get userLists => '유저 리스트';

  @override
  String get noUserLists => '생성된 리스트가 없습니다.';

  @override
  String get sortLatest => '최신순';

  @override
  String get sortHighRating => '높은점수';

  @override
  String get sortReliability => '신뢰도순';

  @override
  String get sortBitter => '쓴소리';

  @override
  String get noReviews => '작성한 리뷰가 없습니다.';

  @override
  String get blockUserTitle => '차단하기';

  @override
  String blockUserContent(Object nickname) {
    return '$nickname를 차단하시겠습니까?\n차단하면 서로의 게시물을 볼 수 없습니다.';
  }

  @override
  String get block => '차단';

  @override
  String get userBlocked => '사용자를 차단했습니다.';

  @override
  String get blockFailed => '차단 처리 중 오류가 발생했습니다.';

  @override
  String get unblocked => '차단이 해제되었습니다.';

  @override
  String get blockedUserTitle => '차단한 사용자입니다.';

  @override
  String get blockedUserContent => '차단을 해제해야 프로필을 볼 수 있습니다.';

  @override
  String get blockedByTitle => '차단 당한 사용자입니다.';

  @override
  String get blockedByContent => '이 사용자의 프로필을 볼 수 없습니다.';

  @override
  String get userNotFound => '유저 정보를 찾을 수 없습니다.';

  @override
  String usersLists(Object nickname) {
    return '$nickname님의 리스트';
  }

  @override
  String savedStoresCount(Object count) {
    return '저장된 매장 $count개';
  }

  @override
  String get weeklyNeedsFineRanking => '주간 니즈파인 랭킹';

  @override
  String get noRankingData => '랭킹 데이터가 없습니다.';

  @override
  String get all => '전체';

  @override
  String get nearMe => '내주변';

  @override
  String get deleteConfirmTitle => '삭제 확인';

  @override
  String get deleteConfirmContent => '정말로 삭제하시겠습니까? 복구할 수 없습니다.';

  @override
  String get deleteAction => '削除';

  @override
  String get edit => '수정';

  @override
  String get userRating => '사용자 별점';

  @override
  String get helpful => '도움돼요';

  @override
  String get save => '저장하기';

  @override
  String get report => '신고';

  @override
  String get noComments => '아직 댓글이 없습니다.\n첫 댓글을 남겨보세요!';

  @override
  String get reportReason1 => '비방 및 불건전한 내용';

  @override
  String get reportReason2 => '부적절한 게시물';

  @override
  String get reportReason3 => '개인정보 및 광고';

  @override
  String get reportReason4 => '불법 행위';

  @override
  String get reportReason5 => '서비스 관련';

  @override
  String get reportSubmitted => '신고가 접수되었습니다.';

  @override
  String get alreadyReported => '이미 신고한 리뷰입니다.';

  @override
  String get unknownStore => '不明店';

  @override
  String get notices => 'お知らせ';

  @override
  String get writeNotice => '作成';

  @override
  String get searchStoreHint => '매장 검색';

  @override
  String get writeReviewTitle => '리뷰 작성';

  @override
  String get editReviewTitle => '리뷰 수정';

  @override
  String get findStoreTitle => '방문한 맛집을 찾아주세요';

  @override
  String get findStoreSubtitle => '정확한 장소 선택이 신뢰도의 시작입니다';

  @override
  String get ratingTitle => '전반적인 경험은 어떠셨나요?';

  @override
  String get featureTitle => '이곳의 특징을 선택해주세요';

  @override
  String get reviewHint => '메뉴의 맛, 매장의 분위기, 직원 서비스 등\\n솔직한 경험을 공유해주세요.';

  @override
  String get submitReviewTitle => '리뷰 등록하기';

  @override
  String get editReviewComplete => '수정 완료';

  @override
  String get guideTitle => '커뮤니티 가이드라인';

  @override
  String get guide1Title => '부적절한 콘텐츠 금지';

  @override
  String get guide1Desc => '욕설, 비방, 혐오 발언, 성적 콘텐츠, 폭력적인 내용은 엄격히 금지되며 필터링됩니다.';

  @override
  String get guide2Title => '사용자 신고 및 차단';

  @override
  String get guide2Desc => '불쾌한 유저는 프로필 또는 리뷰에서 즉시 \'신고\' 및 \'차단\'할 수 있습니다.';

  @override
  String get guide3Title => '신고 처리 정책';

  @override
  String get guide3Desc => '접수된 신고는 운영팀이 24시간 이내에 검토하며, 위반 시 제재 조치가 취해집니다.';

  @override
  String get visitPurposeSolo => '혼자서 👤';

  @override
  String get visitPurposeCouple => '둘이서 👩‍❤️‍👨';

  @override
  String get visitPurposeGroup => '여럿이 👨‍👩‍👧‍👦';

  @override
  String get tagSoloEating => '혼밥';

  @override
  String get tagHealing => '힐링';

  @override
  String get tagCostEffective => '가성비';

  @override
  String get tagBrunch => '브런치';

  @override
  String get tagTakeout => '포장가능';

  @override
  String get tagDelivery => '배달';

  @override
  String get tagQuiet => '조용한';

  @override
  String get tagSimple => '간편한';

  @override
  String get tagDate => '데이트';

  @override
  String get tagAnniversary => '기념일';

  @override
  String get tagAtmosphere => '분위기맛집';

  @override
  String get tagView => '뷰맛집';

  @override
  String get tagExotic => '이색요리';

  @override
  String get tagWine => '와인';

  @override
  String get tagCourse => '코스요리';

  @override
  String get tagCompanyDinner => '회식';

  @override
  String get tagFamily => '가족모임';

  @override
  String get tagFriends => '친구모임';

  @override
  String get tagParking => '주차가능';

  @override
  String get tagPrivateRoom => '룸있음';

  @override
  String get tagConversation => '대화하기좋은';

  @override
  String get tagSpacious => '넓은좌석';

  @override
  String get notificationsTitle => '알림';

  @override
  String get tabAll => '전체';

  @override
  String get tabFollow => '팔로우';

  @override
  String get tabActivity => '활동';

  @override
  String commentNotification(Object user, Object store) {
    return '$user님이 당신의 $store 리뷰에 댓글을 달았습니다';
  }

  @override
  String likeNotification(Object store, Object user) {
    return '당신의 $store의 리뷰가 $user님에게 도움이 되었습니다';
  }

  @override
  String get sendSuggestionTitle => '건의사항 보내기';

  @override
  String get suggestionGuide =>
      '니즈파인 발전을 위한 의견을 남겨주세요.\\n관리자가 직접 확인 후 반영하겠습니다.';

  @override
  String get suggestionHint => '내용을 입력해주세요...';

  @override
  String get sendAction => '보내기';

  @override
  String get inquiryTitle => '1:1 문의하기';

  @override
  String get inquiryGuide => '궁금한 점이나 불편한 점을 남겨주세요. 입력하신 이메일로 답변을 보내드립니다.';

  @override
  String get emailLabel => '답변 받을 이메일';

  @override
  String get inquiryHint => '문의 내용을 자세히 적어주세요...';

  @override
  String get inquiryAction => '문의하기';

  @override
  String get selectStore => '가게를 선택해주세요';

  @override
  String get selectRating => '별점을 선택해주세요';

  @override
  String get profanityError => '부적절한 단어가 포함되어 있습니다';

  @override
  String get reviewUpdated => '리뷰가 수정되었습니다';

  @override
  String get reviewSubmitted => '리뷰가 등록되었습니다';

  @override
  String processFailed(Object error) {
    return '처리 실패: $error';
  }

  @override
  String get photoLimit => '최대 5장까지 첨부 가능합니다';

  @override
  String get noReviewsYet => '아직 등록된 리뷰가 없습니다';

  @override
  String get firstReviewWaiting => '첫 번째 리뷰를 기다리고 있어요';

  @override
  String get savedCount => '저장됨';

  @override
  String get loadingError => '로딩 중 오류가 발생했습니다';

  @override
  String get editProfileTitle => '프로필 수정';

  @override
  String get nicknameLabel => '닉네임';

  @override
  String get introLabel => '소개';

  @override
  String get activityZoneLabel => '활동 지역';

  @override
  String get introHint => '자신을 알릴 수 있는 소개글을 작성해 주세요.';

  @override
  String get nicknameTaken => '이미 사용 중인 닉네임입니다';

  @override
  String get nicknameRule => '2자 이상 10자 이내 (한글/영문/숫자)';

  @override
  String get selectSido => '시/도 선택';

  @override
  String get selectSigungu => '시/군/구 선택';

  @override
  String get saveAction => '저장';

  @override
  String get recalcWarningTitle => '⚠️ 전체 재계산 경고';

  @override
  String get recalcWarningContent =>
      '서버 부하가 발생할 수 있습니다.\n정말 모든 리뷰의 점수를 재계산하시겠습니까?';

  @override
  String get finalConfirmTitle => '🛑 최종 확인';

  @override
  String get finalConfirmContent => '이 작업은 되돌릴 수 없습니다.\n정말로 진행하시겠습니까?';

  @override
  String get cancelAction => '취소';

  @override
  String get continueAction => '계속';

  @override
  String get confirmAction => '확인';

  @override
  String get executeAction => '실행!';

  @override
  String get recalcRequesting => '재계산 요청 중...';

  @override
  String get recalcCompleteTitle => '✅ 재계산 완료';

  @override
  String recalcCompleteContent(Object count, Object version) {
    return '총 $count 개의 리뷰가 업데이트되었습니다.\n\n적용된 로직 버전:\n👉 $version';
  }

  @override
  String get checked => '확인됨';

  @override
  String get nicknameUnavailable => '해당 닉네임은 사용할 수 없습니다';

  @override
  String get nicknameCurrent => '현재 사용 중인 닉네임입니다';

  @override
  String get completionAction => '완료';

  @override
  String get satisfactionHigh => '만족도 높음';

  @override
  String get exaggeratedExpression => '과장된 표현';

  @override
  String get anonymousUser => '익명 사용자';

  @override
  String get predictedNeedsFineScore => '예상 니즈파인 점수';

  @override
  String get whereDidYouGo => '어디를 다녀오셨나요?';

  @override
  String get searchStoreName => '가게 이름 검색';

  @override
  String get noSearchResults => '검색 결과가 없습니다.';

  @override
  String get points => '점';

  @override
  String get overallExperience => '전반적인 경험은 어떠셨나요?';

  @override
  String get selectFeatures => '이곳의 특징을 선택해주세요';

  @override
  String get mostMemorableTaste => '가장 기억에 남는 맛은 무엇이었나요?';

  @override
  String get cgTitle => '커뮤니티 가이드라인 (신고 정책)';

  @override
  String get cgItem1Title => '1. 부적절한 콘텐츠 금지';

  @override
  String get cgItem1Desc => '욕설, 비방, 혐오 발언, 성적 콘텐츠, 폭력적인 내용은 엄격히 금지되며 필터링됩니다.';

  @override
  String get cgItem2Title => '2. 사용자 신고 및 차단';

  @override
  String get cgItem2Desc =>
      '불쾌한 유저는 프로필 또는 리뷰에서 즉시 \'신고\' 및 \'차단\'할 수 있습니다.\n차단 시 해당 유저의 모든 콘텐츠가 숨김 처리됩니다.';

  @override
  String get cgItem3Title => '3. 신고 처리 정책 (24시간 내 조치)';

  @override
  String get cgItem3Desc =>
      '접수된 신고는 운영팀이 24시간 이내에 검토합니다.\n가이드라인 위반이 확인될 경우, 해당 콘텐츠 삭제 및 작성자 이용 제재 조치가 취해집니다.';

  @override
  String get preciseLocationNotFound => '정확한 좌표를 찾을 수 없습니다.';

  @override
  String get verifyingAddress => '주소를 확인 중입니다. 잠시 후 다시 시도해주세요.';

  @override
  String get enterContent => '내용을 입력해주세요';

  @override
  String get selectStoreRequired => '맛집을 추천하려면 가게를 선택해주세요';

  @override
  String get emptyVoteOption => '빈 투표 항목이 있습니다';

  @override
  String get postCreated => '게시물이 등록되었습니다!';

  @override
  String get postUpdated => '게시물이 수정되었습니다!';

  @override
  String get editPost => '게시물 수정';

  @override
  String get newPost => '새 게시물';

  @override
  String get tabStore => '맛집 정보';

  @override
  String get tabQuestion => '질문';

  @override
  String get tabVote => '투표';

  @override
  String get hintReview => '이 맛집의 어떤 점이 좋았나요?';

  @override
  String get hintQuestion => '궁금한 점을 자유롭게 물어보세요!';

  @override
  String get hintVote => '투표 주제를 입력해주세요.';

  @override
  String get voteOption => '선택지';

  @override
  String get addOption => '선택지 추가';

  @override
  String get voteEditWarning => '* 투표 항목은 수정할 수 없습니다.';

  @override
  String get selectStoreHint => '등록할 매장을 검색해주세요';

  @override
  String get editAction => '수정하기';

  @override
  String get postAction => '게시하기';

  @override
  String get deletePost => '게시물 삭제';

  @override
  String get deletePostConfirm => '이 게시물을 삭제하시겠습니까?';

  @override
  String get delete => '삭제';

  @override
  String get viewCount => '조회수';

  @override
  String get topTastes => '리뷰 기반 상위 취향';

  @override
  String get inquirySuccess => '문의가 접수되었습니다. 최대한 빨리 답변 드리겠습니다.';

  @override
  String get suggestions => '건의사항';

  @override
  String get noSuggestions => '등록된 건의사항이 없습니다.';

  @override
  String get noInquiries => '등록된 문의가 없습니다.';

  @override
  String get noNoticesAdmin => '등록된 공지사항이 없습니다.';

  @override
  String get noTitle => '제목 없음';

  @override
  String get anonymous => '익명';

  @override
  String get completed => '답변완료';

  @override
  String get pending => '대기중';

  @override
  String get sender => '보낸사람';

  @override
  String get close => '닫기';

  @override
  String get deleteNotice => '공지사항 삭제';

  @override
  String get deleteConfirm => '정말로 삭제하시겠습니까?';

  @override
  String get notificationFollowTitle => '팔로우 알림';

  @override
  String notificationFollowContent(Object name) {
    return '$name님이 회원님을 팔로우하기 시작했습니다.';
  }

  @override
  String get notificationLikeTitle => '도움됨 알림';

  @override
  String notificationLikeContent(Object name, Object storeName) {
    return '$name님이 $storeName 리뷰를 좋아합니다.';
  }

  @override
  String get notificationCommentTitle => '댓글 알림';

  @override
  String notificationCommentContent(Object name, Object text) {
    return '$name님이 댓글을 남겼습니다: $text';
  }

  @override
  String get markAllReadSuccess => '모든 알림을 읽음 처리했습니다.';

  @override
  String get noBitterReviews => '쓴소리 리뷰가 없습니다.';

  @override
  String get inquiryHistory => '나의 문의 내역';

  @override
  String get totalViewCount => '총 조회수';

  @override
  String get termsAndPolicy => '약관 및 정책';

  @override
  String get serviceTerms => '서비스 이용약관';

  @override
  String get privacyPolicy => '개인정보 처리방침';

  @override
  String get locationTerms => '위치기반 서비스 이용약관';

  @override
  String get noPhotos => '사진 없음';

  @override
  String get viewReview => '리뷰 보기';

  @override
  String get writeReview => '리뷰 쓰기';

  @override
  String get noStoreInfo => '매장 정보가 없습니다.';

  @override
  String get shareExperience => '당신의 경험을 공유해주세요';

  @override
  String get writeFirstReview => '첫 리뷰 작성하기';

  @override
  String get regionKorea => '대한민국';

  @override
  String get regionSeoul => '서울';

  @override
  String get regionBusan => '부산';

  @override
  String get regionDaegu => '대구';

  @override
  String get regionIncheon => '인천';

  @override
  String get regionGwangju => '광주광역시';

  @override
  String get regionDaejeon => '대전광역시';

  @override
  String get regionUlsan => '울산광역시';

  @override
  String get regionSejong => '세종특별자치시';

  @override
  String get regionGyeonggi => '경기도';

  @override
  String get regionGangwon => '강원특별자치도';

  @override
  String get regionChungbuk => '충청북도';

  @override
  String get regionChungnam => '충청남도';

  @override
  String get regionJeonbuk => '전북특별자치도';

  @override
  String get regionJeonnam => '전라남도';

  @override
  String get regionGyeongbuk => '경상북도';

  @override
  String get regionGyeongnam => '경상남도';

  @override
  String get regionJeju => '제주특별자치도';

  @override
  String get requestStoreRegistration => '매장 등록 요청';

  @override
  String get storeName => '매장명';

  @override
  String get storeIntro => '소개';

  @override
  String get storeAddress => '주소';

  @override
  String get storePhone => '전화번호';

  @override
  String get storeHours => '운영시간';

  @override
  String get storeMenu => '추천 메뉴 / 메뉴';

  @override
  String get submitRequest => '요청 보내기';

  @override
  String get requestSuccess => '요청이 성공적으로 접수되었습니다. 검토 후 처리해드리겠습니다.';

  @override
  String get openTime => '오픈 시간';

  @override
  String get closeTime => '마감 시간';

  @override
  String get addPhoto => '사진 추가하기';

  @override
  String get storePhoto => '매장 사진 (1장)';
}
