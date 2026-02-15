import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_my.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('my'),
    Locale('pt'),
    Locale('zh')
  ];

  /// No description provided for @category.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get category;

  /// No description provided for @koreanFood.
  ///
  /// In ko, this message translates to:
  /// **'한식'**
  String get koreanFood;

  /// No description provided for @japaneseFood.
  ///
  /// In ko, this message translates to:
  /// **'일식'**
  String get japaneseFood;

  /// No description provided for @chineseFood.
  ///
  /// In ko, this message translates to:
  /// **'중식'**
  String get chineseFood;

  /// No description provided for @westernFood.
  ///
  /// In ko, this message translates to:
  /// **'양식'**
  String get westernFood;

  /// No description provided for @cafe.
  ///
  /// In ko, this message translates to:
  /// **'카페'**
  String get cafe;

  /// No description provided for @dessert.
  ///
  /// In ko, this message translates to:
  /// **'디저트'**
  String get dessert;

  /// No description provided for @fastFood.
  ///
  /// In ko, this message translates to:
  /// **'패스트푸드'**
  String get fastFood;

  /// No description provided for @snackFood.
  ///
  /// In ko, this message translates to:
  /// **'분식'**
  String get snackFood;

  /// No description provided for @weeklyRanking.
  ///
  /// In ko, this message translates to:
  /// **'주간 랭킹'**
  String get weeklyRanking;

  /// No description provided for @more.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get more;

  /// No description provided for @needsFine.
  ///
  /// In ko, this message translates to:
  /// **'니즈파인 점수'**
  String get needsFine;

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'니즈파인'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In ko, this message translates to:
  /// **'진짜가 필요해'**
  String get appTagline;

  /// No description provided for @appSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'경험과 데이터가 만나는 곳'**
  String get appSubtitle;

  /// No description provided for @emailLoginButton.
  ///
  /// In ko, this message translates to:
  /// **'이메일로 로그인'**
  String get emailLoginButton;

  /// No description provided for @emailSignupButton.
  ///
  /// In ko, this message translates to:
  /// **'이메일로 회원가입하기'**
  String get emailSignupButton;

  /// No description provided for @reliability.
  ///
  /// In ko, this message translates to:
  /// **'신뢰도'**
  String get reliability;

  /// No description provided for @reviewRanking.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 랭킹'**
  String get reviewRanking;

  /// No description provided for @totalReviews.
  ///
  /// In ko, this message translates to:
  /// **'총 리뷰'**
  String get totalReviews;

  /// No description provided for @avgNeedsFineScore.
  ///
  /// In ko, this message translates to:
  /// **'평균 니즈파인'**
  String get avgNeedsFineScore;

  /// No description provided for @needsFineScore.
  ///
  /// In ko, this message translates to:
  /// **'니즈파인 점수'**
  String get needsFineScore;

  /// No description provided for @avgReliability.
  ///
  /// In ko, this message translates to:
  /// **'평균 신뢰도'**
  String get avgReliability;

  /// No description provided for @reviewList.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 목록'**
  String get reviewList;

  /// No description provided for @comments.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get comments;

  /// No description provided for @storeRanking.
  ///
  /// In ko, this message translates to:
  /// **'매장 랭킹'**
  String get storeRanking;

  /// No description provided for @sortByScore.
  ///
  /// In ko, this message translates to:
  /// **'니즈파인 점수순'**
  String get sortByScore;

  /// No description provided for @sortByReliability.
  ///
  /// In ko, this message translates to:
  /// **'신뢰도순'**
  String get sortByReliability;

  /// No description provided for @sortByDistance.
  ///
  /// In ko, this message translates to:
  /// **'거리순'**
  String get sortByDistance;

  /// No description provided for @distanceUnit.
  ///
  /// In ko, this message translates to:
  /// **'{distance}km'**
  String distanceUnit(Object distance);

  /// No description provided for @bitterCriticism.
  ///
  /// In ko, this message translates to:
  /// **'쓴소리'**
  String get bitterCriticism;

  /// No description provided for @latestOrder.
  ///
  /// In ko, this message translates to:
  /// **'최신순'**
  String get latestOrder;

  /// No description provided for @noInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보가 없습니다.'**
  String get noInfo;

  /// No description provided for @follow.
  ///
  /// In ko, this message translates to:
  /// **'팔로우'**
  String get follow;

  /// No description provided for @follower.
  ///
  /// In ko, this message translates to:
  /// **'팔로워'**
  String get follower;

  /// No description provided for @following.
  ///
  /// In ko, this message translates to:
  /// **'팔로잉'**
  String get following;

  /// No description provided for @review.
  ///
  /// In ko, this message translates to:
  /// **'리뷰'**
  String get review;

  /// No description provided for @noListGenerated.
  ///
  /// In ko, this message translates to:
  /// **'생성된 리스트가 없습니다.'**
  String get noListGenerated;

  /// No description provided for @highScore.
  ///
  /// In ko, this message translates to:
  /// **'높은점수'**
  String get highScore;

  /// No description provided for @userListTitle.
  ///
  /// In ko, this message translates to:
  /// **'{username}님의 리스트'**
  String userListTitle(Object username);

  /// No description provided for @sortByUserRating.
  ///
  /// In ko, this message translates to:
  /// **'사용자 별점 순'**
  String get sortByUserRating;

  /// No description provided for @sortByReviewCount.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 개수 순'**
  String get sortByReviewCount;

  /// No description provided for @home.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get home;

  /// No description provided for @mySurroundings.
  ///
  /// In ko, this message translates to:
  /// **'내 주변'**
  String get mySurroundings;

  /// No description provided for @myFine.
  ///
  /// In ko, this message translates to:
  /// **'마이파인'**
  String get myFine;

  /// No description provided for @searchStore.
  ///
  /// In ko, this message translates to:
  /// **'매장 검색'**
  String get searchStore;

  /// No description provided for @editProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필 수정'**
  String get editProfile;

  /// No description provided for @myFeed.
  ///
  /// In ko, this message translates to:
  /// **'나의 피드'**
  String get myFeed;

  /// No description provided for @reviewCollection.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 모음'**
  String get reviewCollection;

  /// No description provided for @myOwnList.
  ///
  /// In ko, this message translates to:
  /// **'나만의 리스트'**
  String get myOwnList;

  /// No description provided for @myTaste.
  ///
  /// In ko, this message translates to:
  /// **'나의 입맛'**
  String get myTaste;

  /// No description provided for @customerCenter.
  ///
  /// In ko, this message translates to:
  /// **'고객센터'**
  String get customerCenter;

  /// No description provided for @notice.
  ///
  /// In ko, this message translates to:
  /// **'공지사항'**
  String get notice;

  /// No description provided for @notifications.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notifications;

  /// No description provided for @newComment.
  ///
  /// In ko, this message translates to:
  /// **'새로운 댓글'**
  String get newComment;

  /// No description provided for @reviewHelpful.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 도움됨'**
  String get reviewHelpful;

  /// No description provided for @newNotice.
  ///
  /// In ko, this message translates to:
  /// **'새로운 공지사항'**
  String get newNotice;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @phoneNumber.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 번호'**
  String get phoneNumber;

  /// No description provided for @verificationNeeded.
  ///
  /// In ko, this message translates to:
  /// **'인증 필요'**
  String get verificationNeeded;

  /// No description provided for @email.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get email;

  /// No description provided for @gender.
  ///
  /// In ko, this message translates to:
  /// **'성별'**
  String get gender;

  /// No description provided for @unspecified.
  ///
  /// In ko, this message translates to:
  /// **'미설정'**
  String get unspecified;

  /// No description provided for @languageSettings.
  ///
  /// In ko, this message translates to:
  /// **'언어 설정'**
  String get languageSettings;

  /// No description provided for @changePassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경'**
  String get changePassword;

  /// No description provided for @notificationSettings.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notificationSettings;

  /// No description provided for @termsOfService.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get termsOfService;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @currentVersion.
  ///
  /// In ko, this message translates to:
  /// **'현재 버전'**
  String get currentVersion;

  /// No description provided for @deleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴하기'**
  String get deleteAccount;

  /// No description provided for @sendSuggestion.
  ///
  /// In ko, this message translates to:
  /// **'건의사항 보내기'**
  String get sendSuggestion;

  /// No description provided for @inquiry.
  ///
  /// In ko, this message translates to:
  /// **'1:1 문의'**
  String get inquiry;

  /// No description provided for @accountInfo.
  ///
  /// In ko, this message translates to:
  /// **'계정 정보'**
  String get accountInfo;

  /// No description provided for @general.
  ///
  /// In ko, this message translates to:
  /// **'일반'**
  String get general;

  /// No description provided for @securityAndNotifications.
  ///
  /// In ko, this message translates to:
  /// **'보안 및 알림'**
  String get securityAndNotifications;

  /// No description provided for @info.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get info;

  /// No description provided for @apply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get apply;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @developingMessage.
  ///
  /// In ko, this message translates to:
  /// **'현재 개발 중인 기능입니다.'**
  String get developingMessage;

  /// No description provided for @noName.
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get noName;

  /// No description provided for @noIntro.
  ///
  /// In ko, this message translates to:
  /// **'소개글이 없습니다.'**
  String get noIntro;

  /// No description provided for @loadError.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러올 수 없습니다'**
  String get loadError;

  /// No description provided for @adminMenu.
  ///
  /// In ko, this message translates to:
  /// **'관리자 메뉴'**
  String get adminMenu;

  /// No description provided for @whatIsScore.
  ///
  /// In ko, this message translates to:
  /// **'니즈파인 점수란?'**
  String get whatIsScore;

  /// No description provided for @scoreDesc.
  ///
  /// In ko, this message translates to:
  /// **'단순 평점이 아닌, 신뢰도와 리뷰어 성향까지 반영된 진짜 맛집 점수입니다.'**
  String get scoreDesc;

  /// No description provided for @waitingSpot.
  ///
  /// In ko, this message translates to:
  /// **'웨이팅 필수! 검증된 맛집'**
  String get waitingSpot;

  /// No description provided for @localSpot.
  ///
  /// In ko, this message translates to:
  /// **'동네 주민이 사랑하는 찐맛집'**
  String get localSpot;

  /// No description provided for @goodSpot.
  ///
  /// In ko, this message translates to:
  /// **'실패 없는 선택'**
  String get goodSpot;

  /// No description provided for @polarizingSpot.
  ///
  /// In ko, this message translates to:
  /// **'호불호가 갈릴 수 있어요'**
  String get polarizingSpot;

  /// No description provided for @whatIsReliability.
  ///
  /// In ko, this message translates to:
  /// **'신뢰도란?'**
  String get whatIsReliability;

  /// No description provided for @reliabilityDesc.
  ///
  /// In ko, this message translates to:
  /// **'사용자의 리뷰를 다른 사용자가 신뢰할 수 있는 퍼센트'**
  String get reliabilityDesc;

  /// No description provided for @movingToMap.
  ///
  /// In ko, this message translates to:
  /// **'(으)로 이동합니다.'**
  String get movingToMap;

  /// No description provided for @noNewNotifications.
  ///
  /// In ko, this message translates to:
  /// **'새로운 알림이 없습니다.'**
  String get noNewNotifications;

  /// No description provided for @checkReview.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 확인하러 가기'**
  String get checkReview;

  /// No description provided for @viewAllNotices.
  ///
  /// In ko, this message translates to:
  /// **'공지사항 전체보기'**
  String get viewAllNotices;

  /// No description provided for @deletedReview.
  ///
  /// In ko, this message translates to:
  /// **'삭제된 리뷰입니다.'**
  String get deletedReview;

  /// No description provided for @deletedComment.
  ///
  /// In ko, this message translates to:
  /// **'삭제된 댓글입니다.'**
  String get deletedComment;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get loading;

  /// No description provided for @followNotification.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 팔로우 했어요'**
  String followNotification(Object name);

  /// No description provided for @unfollowMessage.
  ///
  /// In ko, this message translates to:
  /// **'{name}님 팔로우를 취소합니다.'**
  String unfollowMessage(Object name);

  /// No description provided for @emailLogin.
  ///
  /// In ko, this message translates to:
  /// **'이메일 로그인'**
  String get emailLogin;

  /// No description provided for @welcomeBack.
  ///
  /// In ko, this message translates to:
  /// **'반가워요!\n이메일로 로그인을 진행해주세요.'**
  String get welcomeBack;

  /// No description provided for @emailAddress.
  ///
  /// In ko, this message translates to:
  /// **'이메일 주소'**
  String get emailAddress;

  /// No description provided for @emailPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'example@email.com'**
  String get emailPlaceholder;

  /// No description provided for @password.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In ko, this message translates to:
  /// **'로그인하기'**
  String get loginButton;

  /// No description provided for @loginRequired.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요합니다.'**
  String get loginRequired;

  /// No description provided for @invalidCredentials.
  ///
  /// In ko, this message translates to:
  /// **'이메일 또는 비밀번호가 일치하지 않습니다.'**
  String get invalidCredentials;

  /// No description provided for @serverError.
  ///
  /// In ko, this message translates to:
  /// **'서버 연결에 실패했습니다.'**
  String get serverError;

  /// No description provided for @loginInfoError.
  ///
  /// In ko, this message translates to:
  /// **'로그인 정보가 올바르지 않습니다.'**
  String get loginInfoError;

  /// No description provided for @savedStores.
  ///
  /// In ko, this message translates to:
  /// **'저장한 매장'**
  String get savedStores;

  /// No description provided for @allSavedStores.
  ///
  /// In ko, this message translates to:
  /// **'내가 찜한 모든 매장'**
  String get allSavedStores;

  /// No description provided for @myListsTab.
  ///
  /// In ko, this message translates to:
  /// **'내 리스트'**
  String get myListsTab;

  /// No description provided for @sharedListsTab.
  ///
  /// In ko, this message translates to:
  /// **'공유한 리스트'**
  String get sharedListsTab;

  /// No description provided for @noListsYet.
  ///
  /// In ko, this message translates to:
  /// **'리스트가 없습니다.\n새로운 리스트를 만들어보세요!'**
  String get noListsYet;

  /// No description provided for @noSharedLists.
  ///
  /// In ko, this message translates to:
  /// **'공유한 리스트가 없습니다.'**
  String get noSharedLists;

  /// No description provided for @createList.
  ///
  /// In ko, this message translates to:
  /// **'리스트 만들기'**
  String get createList;

  /// No description provided for @newListTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 리스트 만들기'**
  String get newListTitle;

  /// No description provided for @newListHint.
  ///
  /// In ko, this message translates to:
  /// **'리스트를 만든 후 저장한 매장을 담을 수 있어요.'**
  String get newListHint;

  /// No description provided for @listNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 데이트 맛집, 회식 장소'**
  String get listNamePlaceholder;

  /// No description provided for @createButton.
  ///
  /// In ko, this message translates to:
  /// **'생성'**
  String get createButton;

  /// No description provided for @tapToAddStores.
  ///
  /// In ko, this message translates to:
  /// **'터치하여 매장 추가하기'**
  String get tapToAddStores;

  /// No description provided for @deleteList.
  ///
  /// In ko, this message translates to:
  /// **'리스트 삭제'**
  String get deleteList;

  /// No description provided for @shareList.
  ///
  /// In ko, this message translates to:
  /// **'공개로 전환'**
  String get shareList;

  /// No description provided for @makePrivate.
  ///
  /// In ko, this message translates to:
  /// **'비공개로 전환'**
  String get makePrivate;

  /// No description provided for @deleteListConfirm.
  ///
  /// In ko, this message translates to:
  /// **'리스트 삭제'**
  String get deleteListConfirm;

  /// No description provided for @deleteListMessage.
  ///
  /// In ko, this message translates to:
  /// **'\"{listName}\" 리스트를 삭제하시겠습니까?\n리스트 내 모든 항목이 함께 삭제됩니다.'**
  String deleteListMessage(Object listName);

  /// No description provided for @listDeleted.
  ///
  /// In ko, this message translates to:
  /// **'리스트가 삭제되었습니다.'**
  String get listDeleted;

  /// No description provided for @listShared.
  ///
  /// In ko, this message translates to:
  /// **'리스트가 공개로 설정되었습니다.'**
  String get listShared;

  /// No description provided for @listPrivate.
  ///
  /// In ko, this message translates to:
  /// **'리스트가 비공개로 설정되었습니다.'**
  String get listPrivate;

  /// No description provided for @deleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제에 실패했습니다.'**
  String get deleteFailed;

  /// No description provided for @settingFailed.
  ///
  /// In ko, this message translates to:
  /// **'설정 변경에 실패했습니다.'**
  String get settingFailed;

  /// No description provided for @listCreated.
  ///
  /// In ko, this message translates to:
  /// **'리스트가 생성되었습니다. 매장을 추가해보세요!'**
  String get listCreated;

  /// No description provided for @itemCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String itemCount(Object count);

  /// No description provided for @addStores.
  ///
  /// In ko, this message translates to:
  /// **'매장 추가'**
  String get addStores;

  /// No description provided for @noStoresInList.
  ///
  /// In ko, this message translates to:
  /// **'아직 리스트에 담긴 매장이 없습니다.\n우측 상단 +로 저장한 매장을 추가해보세요.'**
  String get noStoresInList;

  /// No description provided for @alreadyAdded.
  ///
  /// In ko, this message translates to:
  /// **'추가됨'**
  String get alreadyAdded;

  /// No description provided for @addToList.
  ///
  /// In ko, this message translates to:
  /// **'리스트에 추가'**
  String get addToList;

  /// No description provided for @addedToList.
  ///
  /// In ko, this message translates to:
  /// **'리스트에 추가했습니다.'**
  String get addedToList;

  /// No description provided for @removeFromList.
  ///
  /// In ko, this message translates to:
  /// **'리스트에서 제거'**
  String get removeFromList;

  /// No description provided for @signup.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get signup;

  /// No description provided for @searchPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'맛집, 지역, 음식 등으로 검색해보세요'**
  String get searchPlaceholder;

  /// No description provided for @realTimeBestReviews.
  ///
  /// In ko, this message translates to:
  /// **'실시간 베스트 리뷰'**
  String get realTimeBestReviews;

  /// No description provided for @imagePreparing.
  ///
  /// In ko, this message translates to:
  /// **'등록된 이미지가 없음'**
  String get imagePreparing;

  /// No description provided for @rank.
  ///
  /// In ko, this message translates to:
  /// **'위'**
  String get rank;

  /// No description provided for @trustScore.
  ///
  /// In ko, this message translates to:
  /// **'신뢰도'**
  String get trustScore;

  /// No description provided for @passwordRequirement.
  ///
  /// In ko, this message translates to:
  /// **'8자 이상, 영문 대/소문자, 특수문자 포함'**
  String get passwordRequirement;

  /// No description provided for @passwordValid.
  ///
  /// In ko, this message translates to:
  /// **'사용 가능한 비밀번호입니다.'**
  String get passwordValid;

  /// No description provided for @passwordMatch.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 일치합니다.'**
  String get passwordMatch;

  /// No description provided for @passwordMismatch.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 일치하지 않습니다.'**
  String get passwordMismatch;

  /// No description provided for @signupFailed.
  ///
  /// In ko, this message translates to:
  /// **'가입 실패'**
  String get signupFailed;

  /// No description provided for @myActivity.
  ///
  /// In ko, this message translates to:
  /// **'나의 활동'**
  String get myActivity;

  /// No description provided for @customerSupport.
  ///
  /// In ko, this message translates to:
  /// **'고객 지원'**
  String get customerSupport;

  /// No description provided for @noImages.
  ///
  /// In ko, this message translates to:
  /// **'이미지가 없습니다'**
  String get noImages;

  /// No description provided for @invalidEmail.
  ///
  /// In ko, this message translates to:
  /// **'올바른 이메일을 입력해주세요.'**
  String get invalidEmail;

  /// No description provided for @authCodeSent.
  ///
  /// In ko, this message translates to:
  /// **'인증번호가 발송되었습니다. 메일함을 확인해주세요.'**
  String get authCodeSent;

  /// No description provided for @sendFailed.
  ///
  /// In ko, this message translates to:
  /// **'발송 실패: {error}'**
  String sendFailed(Object error);

  /// No description provided for @invalidAuthCodeLength.
  ///
  /// In ko, this message translates to:
  /// **'인증번호 6자리를 입력해주세요.'**
  String get invalidAuthCodeLength;

  /// No description provided for @emailVerified.
  ///
  /// In ko, this message translates to:
  /// **'이메일 인증이 완료되었습니다.'**
  String get emailVerified;

  /// No description provided for @verificationFailed.
  ///
  /// In ko, this message translates to:
  /// **'인증 실패'**
  String get verificationFailed;

  /// No description provided for @invalidAuthCode.
  ///
  /// In ko, this message translates to:
  /// **'인증번호가 올바르지 않거나 만료되었습니다.'**
  String get invalidAuthCode;

  /// No description provided for @nicknameRequired.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요'**
  String get nicknameRequired;

  /// No description provided for @signupError.
  ///
  /// In ko, this message translates to:
  /// **'가입 처리 중 오류 발생: {error}'**
  String signupError(Object error);

  /// No description provided for @sessionExpired.
  ///
  /// In ko, this message translates to:
  /// **'로그인 세션이 만료되었습니다. 처음부터 다시 시도해주세요.'**
  String get sessionExpired;

  /// No description provided for @emailAutoVerified.
  ///
  /// In ko, this message translates to:
  /// **'이메일 확인되었습니다. (인증 생략됨)'**
  String get emailAutoVerified;

  /// No description provided for @enterEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력해주세요.'**
  String get enterEmail;

  /// No description provided for @emailUsageInfo.
  ///
  /// In ko, this message translates to:
  /// **'로그인 및 계정 찾기에 사용됩니다.'**
  String get emailUsageInfo;

  /// No description provided for @authCode.
  ///
  /// In ko, this message translates to:
  /// **'인증번호 6자리'**
  String get authCode;

  /// No description provided for @requestAuth.
  ///
  /// In ko, this message translates to:
  /// **'인증요청'**
  String get requestAuth;

  /// No description provided for @resend.
  ///
  /// In ko, this message translates to:
  /// **'재전송'**
  String get resend;

  /// No description provided for @next.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// No description provided for @setPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 설정해주세요'**
  String get setPassword;

  /// No description provided for @passwordHint.
  ///
  /// In ko, this message translates to:
  /// **'영문, 숫자, 특수문자 포함 8자 이상'**
  String get passwordHint;

  /// No description provided for @enterPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 입력'**
  String get enterPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 확인'**
  String get confirmPassword;

  /// No description provided for @reenterPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재입력'**
  String get reenterPassword;

  /// No description provided for @whereDoYouLive.
  ///
  /// In ko, this message translates to:
  /// **'어디에 거주하시나요?'**
  String get whereDoYouLive;

  /// No description provided for @regionInfo.
  ///
  /// In ko, this message translates to:
  /// **'동네 맛집 추천을 위해 필요해요.'**
  String get regionInfo;

  /// No description provided for @city.
  ///
  /// In ko, this message translates to:
  /// **'시/도'**
  String get city;

  /// No description provided for @district.
  ///
  /// In ko, this message translates to:
  /// **'시/군/구'**
  String get district;

  /// No description provided for @setNickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 정해주세요'**
  String get setNickname;

  /// No description provided for @nicknameInfo.
  ///
  /// In ko, this message translates to:
  /// **'나중에 언제든 변경할 수 있어요.'**
  String get nicknameInfo;

  /// No description provided for @nickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get nickname;

  /// No description provided for @nicknameHint.
  ///
  /// In ko, this message translates to:
  /// **'한글, 영문, 숫자 포함 2~10자'**
  String get nicknameHint;

  /// No description provided for @checkDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'중복확인'**
  String get checkDuplicate;

  /// No description provided for @nicknameEmpty.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요.'**
  String get nicknameEmpty;

  /// No description provided for @nicknameTooShort.
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 2자 이상이어야 합니다.'**
  String get nicknameTooShort;

  /// No description provided for @nicknameDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 닉네임입니다.'**
  String get nicknameDuplicate;

  /// No description provided for @nicknameAvailable.
  ///
  /// In ko, this message translates to:
  /// **'사용 가능한 닉네임입니다'**
  String get nicknameAvailable;

  /// No description provided for @completeSignup.
  ///
  /// In ko, this message translates to:
  /// **'가입 완료'**
  String get completeSignup;

  /// No description provided for @welcome.
  ///
  /// In ko, this message translates to:
  /// **'환영합니다!'**
  String get welcome;

  /// No description provided for @signupCompleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'NeedsFine 회원가입이 완료되었습니다.'**
  String get signupCompleteMessage;

  /// No description provided for @getStarted.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get getStarted;

  /// No description provided for @feed.
  ///
  /// In ko, this message translates to:
  /// **'피드'**
  String get feed;

  /// No description provided for @birthDate.
  ///
  /// In ko, this message translates to:
  /// **'생년월일'**
  String get birthDate;

  /// No description provided for @birthDateSet.
  ///
  /// In ko, this message translates to:
  /// **'생년월일 설정'**
  String get birthDateSet;

  /// No description provided for @blockedUserManagement.
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자 관리'**
  String get blockedUserManagement;

  /// No description provided for @communityGuidelines.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 가이드라인'**
  String get communityGuidelines;

  /// No description provided for @communityGuidelinesContent.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 가이드라인 내용'**
  String get communityGuidelinesContent;

  /// No description provided for @genderSet.
  ///
  /// In ko, this message translates to:
  /// **'성별 설정'**
  String get genderSet;

  /// No description provided for @myTasteSummary.
  ///
  /// In ko, this message translates to:
  /// **'내 취향 요약'**
  String get myTasteSummary;

  /// No description provided for @analyzeAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 분석하기'**
  String get analyzeAgain;

  /// No description provided for @adminDashboard.
  ///
  /// In ko, this message translates to:
  /// **'관리자 대시보드'**
  String get adminDashboard;

  /// No description provided for @bannerManagement.
  ///
  /// In ko, this message translates to:
  /// **'배너 관리'**
  String get bannerManagement;

  /// No description provided for @reportManagement.
  ///
  /// In ko, this message translates to:
  /// **'신고 관리'**
  String get reportManagement;

  /// No description provided for @recalculateReviews.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 점수 재산정'**
  String get recalculateReviews;

  /// No description provided for @myReviews.
  ///
  /// In ko, this message translates to:
  /// **'내가 쓴 리뷰'**
  String get myReviews;

  /// No description provided for @helpfulReviews.
  ///
  /// In ko, this message translates to:
  /// **'도움이 됐어요'**
  String get helpfulReviews;

  /// No description provided for @commentedReviews.
  ///
  /// In ko, this message translates to:
  /// **'댓글 단 리뷰'**
  String get commentedReviews;

  /// No description provided for @noReviewsWritten.
  ///
  /// In ko, this message translates to:
  /// **'작성한 리뷰가 없습니다.'**
  String get noReviewsWritten;

  /// No description provided for @experienceQuestion.
  ///
  /// In ko, this message translates to:
  /// **'어떤 점이 좋았나요?'**
  String get experienceQuestion;

  /// No description provided for @chooseFeatures.
  ///
  /// In ko, this message translates to:
  /// **'매장의 특징을 선택해주세요.'**
  String get chooseFeatures;

  /// No description provided for @findRestaurant.
  ///
  /// In ko, this message translates to:
  /// **'방문한 맛집을 찾아주세요'**
  String get findRestaurant;

  /// No description provided for @submitReview.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 등록'**
  String get submitReview;

  /// No description provided for @editComplete.
  ///
  /// In ko, this message translates to:
  /// **'수정 완료'**
  String get editComplete;

  /// No description provided for @locationNotFound.
  ///
  /// In ko, this message translates to:
  /// **'위치를 찾을 수 없습니다.'**
  String get locationNotFound;

  /// No description provided for @saveError.
  ///
  /// In ko, this message translates to:
  /// **'저장 중 오류가 발생했습니다.'**
  String get saveError;

  /// No description provided for @calculating.
  ///
  /// In ko, this message translates to:
  /// **'계산 중...'**
  String get calculating;

  /// No description provided for @markAllRead.
  ///
  /// In ko, this message translates to:
  /// **'모두 읽음처리'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In ko, this message translates to:
  /// **'새로운 알림이 없습니다.'**
  String get noNotifications;

  /// No description provided for @notificationComment.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 회원님의 리뷰에 댓글을 남겼습니다.'**
  String notificationComment(Object name);

  /// No description provided for @notificationHelpful.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 회원님의 리뷰를 좋아합니다.'**
  String notificationHelpful(Object name);

  /// No description provided for @editNotice.
  ///
  /// In ko, this message translates to:
  /// **'공지사항 수정'**
  String get editNotice;

  /// No description provided for @title.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get title;

  /// No description provided for @content.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get content;

  /// No description provided for @enterTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력하세요'**
  String get enterTitle;

  /// No description provided for @male.
  ///
  /// In ko, this message translates to:
  /// **'남성'**
  String get male;

  /// No description provided for @female.
  ///
  /// In ko, this message translates to:
  /// **'여성'**
  String get female;

  /// No description provided for @genderOneTime.
  ///
  /// In ko, this message translates to:
  /// **'성별은 한 번만 설정할 수 있습니다.'**
  String get genderOneTime;

  /// No description provided for @birthDateOneTime.
  ///
  /// In ko, this message translates to:
  /// **'생년월일은 한 번만 설정할 수 있습니다.'**
  String get birthDateOneTime;

  /// No description provided for @birthDateSelect.
  ///
  /// In ko, this message translates to:
  /// **'생년월일 선택 (한 번만 설정 가능)'**
  String get birthDateSelect;

  /// No description provided for @saved.
  ///
  /// In ko, this message translates to:
  /// **'저장되었습니다.'**
  String get saved;

  /// No description provided for @unblock.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get unblock;

  /// No description provided for @noBlockedUsers.
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자가 없습니다.'**
  String get noBlockedUsers;

  /// No description provided for @noLikedReviews.
  ///
  /// In ko, this message translates to:
  /// **'도움이 됐어요 표시한 리뷰가 없습니다.'**
  String get noLikedReviews;

  /// No description provided for @noCommentedReviews.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 작성한 리뷰가 없습니다.'**
  String get noCommentedReviews;

  /// No description provided for @addFailed.
  ///
  /// In ko, this message translates to:
  /// **'추가에 실패했습니다.'**
  String get addFailed;

  /// No description provided for @noSavedStores.
  ///
  /// In ko, this message translates to:
  /// **'저장한 매장이 없습니다.'**
  String get noSavedStores;

  /// No description provided for @noReviewsForStore.
  ///
  /// In ko, this message translates to:
  /// **'추가할 수 있는 리뷰가 없는 매장입니다.'**
  String get noReviewsForStore;

  /// No description provided for @addSavedStore.
  ///
  /// In ko, this message translates to:
  /// **'저장한 매장 추가'**
  String get addSavedStore;

  /// No description provided for @added.
  ///
  /// In ko, this message translates to:
  /// **'추가됨'**
  String get added;

  /// No description provided for @selectItemsToAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가할 항목을 선택하세요'**
  String get selectItemsToAdd;

  /// No description provided for @addNItems.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 추가하기'**
  String addNItems(Object count);

  /// No description provided for @emptyListHint.
  ///
  /// In ko, this message translates to:
  /// **'아직 리스트에 담긴 매장이 없습니다.\n우측 상단 +로 저장한 매장을 추가해보세요.'**
  String get emptyListHint;

  /// No description provided for @noSavedStoresHint.
  ///
  /// In ko, this message translates to:
  /// **'저장한 매장이 없습니다.\n마음에 드는 매장을 저장해보세요!'**
  String get noSavedStoresHint;

  /// No description provided for @tasteSurveyTitle.
  ///
  /// In ko, this message translates to:
  /// **'당신은 뭘 좋아하나요?'**
  String get tasteSurveyTitle;

  /// No description provided for @tasteSurveySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'취향을 알려주시면 딱 맞는 맛집을 추천해드려요.\n(30초면 충분해요!)'**
  String get tasteSurveySubtitle;

  /// No description provided for @doItLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에 하기'**
  String get doItLater;

  /// No description provided for @start.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get start;

  /// No description provided for @tasteKorean.
  ///
  /// In ko, this message translates to:
  /// **'한식 파'**
  String get tasteKorean;

  /// No description provided for @tasteChinese.
  ///
  /// In ko, this message translates to:
  /// **'중식 러버'**
  String get tasteChinese;

  /// No description provided for @tasteJapanese.
  ///
  /// In ko, this message translates to:
  /// **'일식 매니아'**
  String get tasteJapanese;

  /// No description provided for @tasteWestern.
  ///
  /// In ko, this message translates to:
  /// **'양식 선호'**
  String get tasteWestern;

  /// No description provided for @tasteSpicyLover.
  ///
  /// In ko, this message translates to:
  /// **'매운맛 고수'**
  String get tasteSpicyLover;

  /// No description provided for @tasteSpicyHater.
  ///
  /// In ko, this message translates to:
  /// **'맵찔이'**
  String get tasteSpicyHater;

  /// No description provided for @tasteCostEffective.
  ///
  /// In ko, this message translates to:
  /// **'가성비 중시'**
  String get tasteCostEffective;

  /// No description provided for @tasteAtmosphere.
  ///
  /// In ko, this message translates to:
  /// **'분위기 깡패'**
  String get tasteAtmosphere;

  /// No description provided for @tasteSolo.
  ///
  /// In ko, this message translates to:
  /// **'혼밥족'**
  String get tasteSolo;

  /// No description provided for @tasteDate.
  ///
  /// In ko, this message translates to:
  /// **'데이트 맛집'**
  String get tasteDate;

  /// No description provided for @tasteDessert.
  ///
  /// In ko, this message translates to:
  /// **'디저트 필수'**
  String get tasteDessert;

  /// No description provided for @tasteOldGen.
  ///
  /// In ko, this message translates to:
  /// **'노포 감성'**
  String get tasteOldGen;

  /// No description provided for @loadFailed.
  ///
  /// In ko, this message translates to:
  /// **'정보를 불러오지 못했습니다.'**
  String get loadFailed;

  /// No description provided for @noNotices.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록된 공지사항이 없어요.'**
  String get noNotices;

  /// No description provided for @noFollowers.
  ///
  /// In ko, this message translates to:
  /// **'아직 팔로워가 없습니다.'**
  String get noFollowers;

  /// No description provided for @noFollowings.
  ///
  /// In ko, this message translates to:
  /// **'팔로잉하는 유저가 없습니다.'**
  String get noFollowings;

  /// No description provided for @followMessage.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}님을 팔로우합니다.'**
  String followMessage(Object nickname);

  /// No description provided for @errorOccurred.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다.'**
  String get errorOccurred;

  /// No description provided for @unknownUser.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 사용자'**
  String get unknownUser;

  /// No description provided for @reviewCount.
  ///
  /// In ko, this message translates to:
  /// **'리뷰'**
  String get reviewCount;

  /// No description provided for @followerCount.
  ///
  /// In ko, this message translates to:
  /// **'팔로워'**
  String get followerCount;

  /// No description provided for @followingCount.
  ///
  /// In ko, this message translates to:
  /// **'팔로잉'**
  String get followingCount;

  /// No description provided for @noIntroduction.
  ///
  /// In ko, this message translates to:
  /// **'소개글이 없습니다.'**
  String get noIntroduction;

  /// No description provided for @tasteAnalysis.
  ///
  /// In ko, this message translates to:
  /// **'취향 분석'**
  String get tasteAnalysis;

  /// No description provided for @scoreDistribution.
  ///
  /// In ko, this message translates to:
  /// **'평점 분포'**
  String get scoreDistribution;

  /// No description provided for @userLists.
  ///
  /// In ko, this message translates to:
  /// **'유저 리스트'**
  String get userLists;

  /// No description provided for @noUserLists.
  ///
  /// In ko, this message translates to:
  /// **'생성된 리스트가 없습니다.'**
  String get noUserLists;

  /// No description provided for @sortLatest.
  ///
  /// In ko, this message translates to:
  /// **'최신순'**
  String get sortLatest;

  /// No description provided for @sortHighRating.
  ///
  /// In ko, this message translates to:
  /// **'높은점수'**
  String get sortHighRating;

  /// No description provided for @sortReliability.
  ///
  /// In ko, this message translates to:
  /// **'신뢰도순'**
  String get sortReliability;

  /// No description provided for @sortBitter.
  ///
  /// In ko, this message translates to:
  /// **'쓴소리'**
  String get sortBitter;

  /// No description provided for @noReviews.
  ///
  /// In ko, this message translates to:
  /// **'작성한 리뷰가 없습니다.'**
  String get noReviews;

  /// No description provided for @blockUserTitle.
  ///
  /// In ko, this message translates to:
  /// **'차단하기'**
  String get blockUserTitle;

  /// No description provided for @blockUserContent.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}를 차단하시겠습니까?\n차단하면 서로의 게시물을 볼 수 없습니다.'**
  String blockUserContent(Object nickname);

  /// No description provided for @block.
  ///
  /// In ko, this message translates to:
  /// **'차단'**
  String get block;

  /// No description provided for @userBlocked.
  ///
  /// In ko, this message translates to:
  /// **'사용자를 차단했습니다.'**
  String get userBlocked;

  /// No description provided for @blockFailed.
  ///
  /// In ko, this message translates to:
  /// **'차단 처리 중 오류가 발생했습니다.'**
  String get blockFailed;

  /// No description provided for @unblocked.
  ///
  /// In ko, this message translates to:
  /// **'차단이 해제되었습니다.'**
  String get unblocked;

  /// No description provided for @blockedUserTitle.
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자입니다.'**
  String get blockedUserTitle;

  /// No description provided for @blockedUserContent.
  ///
  /// In ko, this message translates to:
  /// **'차단을 해제해야 프로필을 볼 수 있습니다.'**
  String get blockedUserContent;

  /// No description provided for @blockedByTitle.
  ///
  /// In ko, this message translates to:
  /// **'차단 당한 사용자입니다.'**
  String get blockedByTitle;

  /// No description provided for @blockedByContent.
  ///
  /// In ko, this message translates to:
  /// **'이 사용자의 프로필을 볼 수 없습니다.'**
  String get blockedByContent;

  /// No description provided for @userNotFound.
  ///
  /// In ko, this message translates to:
  /// **'유저 정보를 찾을 수 없습니다.'**
  String get userNotFound;

  /// No description provided for @usersLists.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}님의 리스트'**
  String usersLists(Object nickname);

  /// No description provided for @savedStoresCount.
  ///
  /// In ko, this message translates to:
  /// **'저장된 매장 {count}개'**
  String savedStoresCount(Object count);

  /// No description provided for @weeklyNeedsFineRanking.
  ///
  /// In ko, this message translates to:
  /// **'주간 니즈파인 랭킹'**
  String get weeklyNeedsFineRanking;

  /// No description provided for @noRankingData.
  ///
  /// In ko, this message translates to:
  /// **'랭킹 데이터가 없습니다.'**
  String get noRankingData;

  /// No description provided for @all.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get all;

  /// No description provided for @nearMe.
  ///
  /// In ko, this message translates to:
  /// **'내주변'**
  String get nearMe;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'삭제 확인'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmContent.
  ///
  /// In ko, this message translates to:
  /// **'정말로 삭제하시겠습니까? 복구할 수 없습니다.'**
  String get deleteConfirmContent;

  /// No description provided for @deleteAction.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get deleteAction;

  /// No description provided for @edit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get edit;

  /// No description provided for @userRating.
  ///
  /// In ko, this message translates to:
  /// **'사용자 별점'**
  String get userRating;

  /// No description provided for @helpful.
  ///
  /// In ko, this message translates to:
  /// **'도움돼요'**
  String get helpful;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장하기'**
  String get save;

  /// No description provided for @report.
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get report;

  /// No description provided for @noComments.
  ///
  /// In ko, this message translates to:
  /// **'아직 댓글이 없습니다.\n첫 댓글을 남겨보세요!'**
  String get noComments;

  /// No description provided for @reportReason1.
  ///
  /// In ko, this message translates to:
  /// **'비방 및 불건전한 내용'**
  String get reportReason1;

  /// No description provided for @reportReason2.
  ///
  /// In ko, this message translates to:
  /// **'부적절한 게시물'**
  String get reportReason2;

  /// No description provided for @reportReason3.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 및 광고'**
  String get reportReason3;

  /// No description provided for @reportReason4.
  ///
  /// In ko, this message translates to:
  /// **'불법 행위'**
  String get reportReason4;

  /// No description provided for @reportReason5.
  ///
  /// In ko, this message translates to:
  /// **'서비스 관련'**
  String get reportReason5;

  /// No description provided for @reportSubmitted.
  ///
  /// In ko, this message translates to:
  /// **'신고가 접수되었습니다.'**
  String get reportSubmitted;

  /// No description provided for @alreadyReported.
  ///
  /// In ko, this message translates to:
  /// **'이미 신고한 리뷰입니다.'**
  String get alreadyReported;

  /// No description provided for @unknownStore.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 가게'**
  String get unknownStore;

  /// No description provided for @notices.
  ///
  /// In ko, this message translates to:
  /// **'공지사항'**
  String get notices;

  /// No description provided for @writeNotice.
  ///
  /// In ko, this message translates to:
  /// **'공지사항 작성'**
  String get writeNotice;

  /// No description provided for @searchStoreHint.
  ///
  /// In ko, this message translates to:
  /// **'매장 검색'**
  String get searchStoreHint;

  /// No description provided for @writeReviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 작성'**
  String get writeReviewTitle;

  /// No description provided for @editReviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 수정'**
  String get editReviewTitle;

  /// No description provided for @findStoreTitle.
  ///
  /// In ko, this message translates to:
  /// **'방문한 맛집을 찾아주세요'**
  String get findStoreTitle;

  /// No description provided for @findStoreSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'정확한 장소 선택이 신뢰도의 시작입니다'**
  String get findStoreSubtitle;

  /// No description provided for @ratingTitle.
  ///
  /// In ko, this message translates to:
  /// **'전반적인 경험은 어떠셨나요?'**
  String get ratingTitle;

  /// No description provided for @featureTitle.
  ///
  /// In ko, this message translates to:
  /// **'이곳의 특징을 선택해주세요'**
  String get featureTitle;

  /// No description provided for @reviewHint.
  ///
  /// In ko, this message translates to:
  /// **'메뉴의 맛, 매장의 분위기, 직원 서비스 등\\n솔직한 경험을 공유해주세요.'**
  String get reviewHint;

  /// No description provided for @submitReviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 등록하기'**
  String get submitReviewTitle;

  /// No description provided for @editReviewComplete.
  ///
  /// In ko, this message translates to:
  /// **'수정 완료'**
  String get editReviewComplete;

  /// No description provided for @guideTitle.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 가이드라인'**
  String get guideTitle;

  /// No description provided for @guide1Title.
  ///
  /// In ko, this message translates to:
  /// **'부적절한 콘텐츠 금지'**
  String get guide1Title;

  /// No description provided for @guide1Desc.
  ///
  /// In ko, this message translates to:
  /// **'욕설, 비방, 혐오 발언, 성적 콘텐츠, 폭력적인 내용은 엄격히 금지되며 필터링됩니다.'**
  String get guide1Desc;

  /// No description provided for @guide2Title.
  ///
  /// In ko, this message translates to:
  /// **'사용자 신고 및 차단'**
  String get guide2Title;

  /// No description provided for @guide2Desc.
  ///
  /// In ko, this message translates to:
  /// **'불쾌한 유저는 프로필 또는 리뷰에서 즉시 \'신고\' 및 \'차단\'할 수 있습니다.'**
  String get guide2Desc;

  /// No description provided for @guide3Title.
  ///
  /// In ko, this message translates to:
  /// **'신고 처리 정책'**
  String get guide3Title;

  /// No description provided for @guide3Desc.
  ///
  /// In ko, this message translates to:
  /// **'접수된 신고는 운영팀이 24시간 이내에 검토하며, 위반 시 제재 조치가 취해집니다.'**
  String get guide3Desc;

  /// No description provided for @visitPurposeSolo.
  ///
  /// In ko, this message translates to:
  /// **'혼자서 👤'**
  String get visitPurposeSolo;

  /// No description provided for @visitPurposeCouple.
  ///
  /// In ko, this message translates to:
  /// **'둘이서 👩‍❤️‍👨'**
  String get visitPurposeCouple;

  /// No description provided for @visitPurposeGroup.
  ///
  /// In ko, this message translates to:
  /// **'여럿이 👨‍👩‍👧‍👦'**
  String get visitPurposeGroup;

  /// No description provided for @tagSoloEating.
  ///
  /// In ko, this message translates to:
  /// **'혼밥'**
  String get tagSoloEating;

  /// No description provided for @tagHealing.
  ///
  /// In ko, this message translates to:
  /// **'힐링'**
  String get tagHealing;

  /// No description provided for @tagCostEffective.
  ///
  /// In ko, this message translates to:
  /// **'가성비'**
  String get tagCostEffective;

  /// No description provided for @tagBrunch.
  ///
  /// In ko, this message translates to:
  /// **'브런치'**
  String get tagBrunch;

  /// No description provided for @tagTakeout.
  ///
  /// In ko, this message translates to:
  /// **'포장가능'**
  String get tagTakeout;

  /// No description provided for @tagDelivery.
  ///
  /// In ko, this message translates to:
  /// **'배달'**
  String get tagDelivery;

  /// No description provided for @tagQuiet.
  ///
  /// In ko, this message translates to:
  /// **'조용한'**
  String get tagQuiet;

  /// No description provided for @tagSimple.
  ///
  /// In ko, this message translates to:
  /// **'간편한'**
  String get tagSimple;

  /// No description provided for @tagDate.
  ///
  /// In ko, this message translates to:
  /// **'데이트'**
  String get tagDate;

  /// No description provided for @tagAnniversary.
  ///
  /// In ko, this message translates to:
  /// **'기념일'**
  String get tagAnniversary;

  /// No description provided for @tagAtmosphere.
  ///
  /// In ko, this message translates to:
  /// **'분위기맛집'**
  String get tagAtmosphere;

  /// No description provided for @tagView.
  ///
  /// In ko, this message translates to:
  /// **'뷰맛집'**
  String get tagView;

  /// No description provided for @tagExotic.
  ///
  /// In ko, this message translates to:
  /// **'이색요리'**
  String get tagExotic;

  /// No description provided for @tagWine.
  ///
  /// In ko, this message translates to:
  /// **'와인'**
  String get tagWine;

  /// No description provided for @tagCourse.
  ///
  /// In ko, this message translates to:
  /// **'코스요리'**
  String get tagCourse;

  /// No description provided for @tagCompanyDinner.
  ///
  /// In ko, this message translates to:
  /// **'회식'**
  String get tagCompanyDinner;

  /// No description provided for @tagFamily.
  ///
  /// In ko, this message translates to:
  /// **'가족모임'**
  String get tagFamily;

  /// No description provided for @tagFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구모임'**
  String get tagFriends;

  /// No description provided for @tagParking.
  ///
  /// In ko, this message translates to:
  /// **'주차가능'**
  String get tagParking;

  /// No description provided for @tagPrivateRoom.
  ///
  /// In ko, this message translates to:
  /// **'룸있음'**
  String get tagPrivateRoom;

  /// No description provided for @tagConversation.
  ///
  /// In ko, this message translates to:
  /// **'대화하기좋은'**
  String get tagConversation;

  /// No description provided for @tagSpacious.
  ///
  /// In ko, this message translates to:
  /// **'넓은좌석'**
  String get tagSpacious;

  /// No description provided for @notificationsTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notificationsTitle;

  /// No description provided for @tabAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get tabAll;

  /// No description provided for @tabFollow.
  ///
  /// In ko, this message translates to:
  /// **'팔로우'**
  String get tabFollow;

  /// No description provided for @tabActivity.
  ///
  /// In ko, this message translates to:
  /// **'활동'**
  String get tabActivity;

  /// No description provided for @commentNotification.
  ///
  /// In ko, this message translates to:
  /// **'{user}님이 당신의 {store} 리뷰에 댓글을 달았습니다'**
  String commentNotification(Object user, Object store);

  /// No description provided for @likeNotification.
  ///
  /// In ko, this message translates to:
  /// **'당신의 {store}의 리뷰가 {user}님에게 도움이 되었습니다'**
  String likeNotification(Object store, Object user);

  /// No description provided for @sendSuggestionTitle.
  ///
  /// In ko, this message translates to:
  /// **'건의사항 보내기'**
  String get sendSuggestionTitle;

  /// No description provided for @suggestionGuide.
  ///
  /// In ko, this message translates to:
  /// **'니즈파인 발전을 위한 의견을 남겨주세요.\\n관리자가 직접 확인 후 반영하겠습니다.'**
  String get suggestionGuide;

  /// No description provided for @suggestionHint.
  ///
  /// In ko, this message translates to:
  /// **'내용을 입력해주세요...'**
  String get suggestionHint;

  /// No description provided for @sendAction.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get sendAction;

  /// No description provided for @inquiryTitle.
  ///
  /// In ko, this message translates to:
  /// **'1:1 문의하기'**
  String get inquiryTitle;

  /// No description provided for @inquiryGuide.
  ///
  /// In ko, this message translates to:
  /// **'궁금한 점이나 불편한 점을 남겨주세요. 입력하신 이메일로 답변을 보내드립니다.'**
  String get inquiryGuide;

  /// No description provided for @emailLabel.
  ///
  /// In ko, this message translates to:
  /// **'답변 받을 이메일'**
  String get emailLabel;

  /// No description provided for @inquiryHint.
  ///
  /// In ko, this message translates to:
  /// **'문의 내용을 자세히 적어주세요...'**
  String get inquiryHint;

  /// No description provided for @inquiryAction.
  ///
  /// In ko, this message translates to:
  /// **'문의하기'**
  String get inquiryAction;

  /// No description provided for @selectStore.
  ///
  /// In ko, this message translates to:
  /// **'가게를 선택해주세요'**
  String get selectStore;

  /// No description provided for @selectRating.
  ///
  /// In ko, this message translates to:
  /// **'별점을 선택해주세요'**
  String get selectRating;

  /// No description provided for @profanityError.
  ///
  /// In ko, this message translates to:
  /// **'부적절한 단어가 포함되어 있습니다'**
  String get profanityError;

  /// No description provided for @reviewUpdated.
  ///
  /// In ko, this message translates to:
  /// **'리뷰가 수정되었습니다'**
  String get reviewUpdated;

  /// No description provided for @reviewSubmitted.
  ///
  /// In ko, this message translates to:
  /// **'리뷰가 등록되었습니다'**
  String get reviewSubmitted;

  /// No description provided for @processFailed.
  ///
  /// In ko, this message translates to:
  /// **'처리 실패: {error}'**
  String processFailed(Object error);

  /// No description provided for @photoLimit.
  ///
  /// In ko, this message translates to:
  /// **'최대 5장까지 첨부 가능합니다'**
  String get photoLimit;

  /// No description provided for @noReviewsYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록된 리뷰가 없습니다'**
  String get noReviewsYet;

  /// No description provided for @firstReviewWaiting.
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 리뷰를 기다리고 있어요'**
  String get firstReviewWaiting;

  /// No description provided for @savedCount.
  ///
  /// In ko, this message translates to:
  /// **'저장됨'**
  String get savedCount;

  /// No description provided for @loadingError.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중 오류가 발생했습니다'**
  String get loadingError;

  /// No description provided for @editProfileTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필 수정'**
  String get editProfileTitle;

  /// No description provided for @nicknameLabel.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get nicknameLabel;

  /// No description provided for @introLabel.
  ///
  /// In ko, this message translates to:
  /// **'소개'**
  String get introLabel;

  /// No description provided for @activityZoneLabel.
  ///
  /// In ko, this message translates to:
  /// **'활동 지역'**
  String get activityZoneLabel;

  /// No description provided for @introHint.
  ///
  /// In ko, this message translates to:
  /// **'자신을 알릴 수 있는 소개글을 작성해 주세요.'**
  String get introHint;

  /// No description provided for @nicknameTaken.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 닉네임입니다'**
  String get nicknameTaken;

  /// No description provided for @nicknameRule.
  ///
  /// In ko, this message translates to:
  /// **'2자 이상 10자 이내 (한글/영문/숫자)'**
  String get nicknameRule;

  /// No description provided for @selectSido.
  ///
  /// In ko, this message translates to:
  /// **'시/도 선택'**
  String get selectSido;

  /// No description provided for @selectSigungu.
  ///
  /// In ko, this message translates to:
  /// **'시/군/구 선택'**
  String get selectSigungu;

  /// No description provided for @saveAction.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get saveAction;

  /// No description provided for @recalcWarningTitle.
  ///
  /// In ko, this message translates to:
  /// **'⚠️ 전체 재계산 경고'**
  String get recalcWarningTitle;

  /// No description provided for @recalcWarningContent.
  ///
  /// In ko, this message translates to:
  /// **'서버 부하가 발생할 수 있습니다.\n정말 모든 리뷰의 점수를 재계산하시겠습니까?'**
  String get recalcWarningContent;

  /// No description provided for @finalConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'🛑 최종 확인'**
  String get finalConfirmTitle;

  /// No description provided for @finalConfirmContent.
  ///
  /// In ko, this message translates to:
  /// **'이 작업은 되돌릴 수 없습니다.\n정말로 진행하시겠습니까?'**
  String get finalConfirmContent;

  /// No description provided for @cancelAction.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancelAction;

  /// No description provided for @continueAction.
  ///
  /// In ko, this message translates to:
  /// **'계속'**
  String get continueAction;

  /// No description provided for @confirmAction.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirmAction;

  /// No description provided for @executeAction.
  ///
  /// In ko, this message translates to:
  /// **'실행!'**
  String get executeAction;

  /// No description provided for @recalcRequesting.
  ///
  /// In ko, this message translates to:
  /// **'재계산 요청 중...'**
  String get recalcRequesting;

  /// No description provided for @recalcCompleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'✅ 재계산 완료'**
  String get recalcCompleteTitle;

  /// No description provided for @recalcCompleteContent.
  ///
  /// In ko, this message translates to:
  /// **'총 {count} 개의 리뷰가 업데이트되었습니다.\n\n적용된 로직 버전:\n👉 {version}'**
  String recalcCompleteContent(Object count, Object version);

  /// No description provided for @checked.
  ///
  /// In ko, this message translates to:
  /// **'확인됨'**
  String get checked;

  /// No description provided for @nicknameUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'해당 닉네임은 사용할 수 없습니다'**
  String get nicknameUnavailable;

  /// No description provided for @nicknameCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 사용 중인 닉네임입니다'**
  String get nicknameCurrent;

  /// No description provided for @completionAction.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get completionAction;

  /// No description provided for @satisfactionHigh.
  ///
  /// In ko, this message translates to:
  /// **'만족도 높음'**
  String get satisfactionHigh;

  /// No description provided for @exaggeratedExpression.
  ///
  /// In ko, this message translates to:
  /// **'과장된 표현'**
  String get exaggeratedExpression;

  /// No description provided for @anonymousUser.
  ///
  /// In ko, this message translates to:
  /// **'익명 사용자'**
  String get anonymousUser;

  /// No description provided for @predictedNeedsFineScore.
  ///
  /// In ko, this message translates to:
  /// **'예상 니즈파인 점수'**
  String get predictedNeedsFineScore;

  /// No description provided for @whereDidYouGo.
  ///
  /// In ko, this message translates to:
  /// **'어디를 다녀오셨나요?'**
  String get whereDidYouGo;

  /// No description provided for @searchStoreName.
  ///
  /// In ko, this message translates to:
  /// **'가게 이름 검색'**
  String get searchStoreName;

  /// No description provided for @noSearchResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다.'**
  String get noSearchResults;

  /// No description provided for @points.
  ///
  /// In ko, this message translates to:
  /// **'점'**
  String get points;

  /// No description provided for @overallExperience.
  ///
  /// In ko, this message translates to:
  /// **'전반적인 경험은 어떠셨나요?'**
  String get overallExperience;

  /// No description provided for @selectFeatures.
  ///
  /// In ko, this message translates to:
  /// **'이곳의 특징을 선택해주세요'**
  String get selectFeatures;

  /// No description provided for @mostMemorableTaste.
  ///
  /// In ko, this message translates to:
  /// **'가장 기억에 남는 맛은 무엇이었나요?'**
  String get mostMemorableTaste;

  /// No description provided for @cgTitle.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 가이드라인 (신고 정책)'**
  String get cgTitle;

  /// No description provided for @cgItem1Title.
  ///
  /// In ko, this message translates to:
  /// **'1. 부적절한 콘텐츠 금지'**
  String get cgItem1Title;

  /// No description provided for @cgItem1Desc.
  ///
  /// In ko, this message translates to:
  /// **'욕설, 비방, 혐오 발언, 성적 콘텐츠, 폭력적인 내용은 엄격히 금지되며 필터링됩니다.'**
  String get cgItem1Desc;

  /// No description provided for @cgItem2Title.
  ///
  /// In ko, this message translates to:
  /// **'2. 사용자 신고 및 차단'**
  String get cgItem2Title;

  /// No description provided for @cgItem2Desc.
  ///
  /// In ko, this message translates to:
  /// **'불쾌한 유저는 프로필 또는 리뷰에서 즉시 \'신고\' 및 \'차단\'할 수 있습니다.\n차단 시 해당 유저의 모든 콘텐츠가 숨김 처리됩니다.'**
  String get cgItem2Desc;

  /// No description provided for @cgItem3Title.
  ///
  /// In ko, this message translates to:
  /// **'3. 신고 처리 정책 (24시간 내 조치)'**
  String get cgItem3Title;

  /// No description provided for @cgItem3Desc.
  ///
  /// In ko, this message translates to:
  /// **'접수된 신고는 운영팀이 24시간 이내에 검토합니다.\n가이드라인 위반이 확인될 경우, 해당 콘텐츠 삭제 및 작성자 이용 제재 조치가 취해집니다.'**
  String get cgItem3Desc;

  /// No description provided for @preciseLocationNotFound.
  ///
  /// In ko, this message translates to:
  /// **'정확한 좌표를 찾을 수 없습니다.'**
  String get preciseLocationNotFound;

  /// No description provided for @verifyingAddress.
  ///
  /// In ko, this message translates to:
  /// **'주소를 확인 중입니다. 잠시 후 다시 시도해주세요.'**
  String get verifyingAddress;

  /// No description provided for @enterContent.
  ///
  /// In ko, this message translates to:
  /// **'내용을 입력해주세요'**
  String get enterContent;

  /// No description provided for @selectStoreRequired.
  ///
  /// In ko, this message translates to:
  /// **'맛집을 추천하려면 가게를 선택해주세요'**
  String get selectStoreRequired;

  /// No description provided for @emptyVoteOption.
  ///
  /// In ko, this message translates to:
  /// **'빈 투표 항목이 있습니다'**
  String get emptyVoteOption;

  /// No description provided for @postCreated.
  ///
  /// In ko, this message translates to:
  /// **'게시물이 등록되었습니다!'**
  String get postCreated;

  /// No description provided for @postUpdated.
  ///
  /// In ko, this message translates to:
  /// **'게시물이 수정되었습니다!'**
  String get postUpdated;

  /// No description provided for @editPost.
  ///
  /// In ko, this message translates to:
  /// **'게시물 수정'**
  String get editPost;

  /// No description provided for @newPost.
  ///
  /// In ko, this message translates to:
  /// **'새 게시물'**
  String get newPost;

  /// No description provided for @tabStore.
  ///
  /// In ko, this message translates to:
  /// **'맛집 정보'**
  String get tabStore;

  /// No description provided for @tabQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문'**
  String get tabQuestion;

  /// No description provided for @tabVote.
  ///
  /// In ko, this message translates to:
  /// **'투표'**
  String get tabVote;

  /// No description provided for @hintReview.
  ///
  /// In ko, this message translates to:
  /// **'이 맛집의 어떤 점이 좋았나요?'**
  String get hintReview;

  /// No description provided for @hintQuestion.
  ///
  /// In ko, this message translates to:
  /// **'궁금한 점을 자유롭게 물어보세요!'**
  String get hintQuestion;

  /// No description provided for @hintVote.
  ///
  /// In ko, this message translates to:
  /// **'투표 주제를 입력해주세요.'**
  String get hintVote;

  /// No description provided for @voteOption.
  ///
  /// In ko, this message translates to:
  /// **'선택지'**
  String get voteOption;

  /// No description provided for @addOption.
  ///
  /// In ko, this message translates to:
  /// **'선택지 추가'**
  String get addOption;

  /// No description provided for @voteEditWarning.
  ///
  /// In ko, this message translates to:
  /// **'* 투표 항목은 수정할 수 없습니다.'**
  String get voteEditWarning;

  /// No description provided for @selectStoreHint.
  ///
  /// In ko, this message translates to:
  /// **'등록할 매장을 검색해주세요'**
  String get selectStoreHint;

  /// No description provided for @editAction.
  ///
  /// In ko, this message translates to:
  /// **'수정하기'**
  String get editAction;

  /// No description provided for @postAction.
  ///
  /// In ko, this message translates to:
  /// **'게시하기'**
  String get postAction;

  /// No description provided for @deletePost.
  ///
  /// In ko, this message translates to:
  /// **'게시물 삭제'**
  String get deletePost;

  /// No description provided for @deletePostConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 게시물을 삭제하시겠습니까?'**
  String get deletePostConfirm;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @viewCount.
  ///
  /// In ko, this message translates to:
  /// **'조회수'**
  String get viewCount;

  /// No description provided for @topTastes.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 기반 상위 취향'**
  String get topTastes;

  /// No description provided for @inquirySuccess.
  ///
  /// In ko, this message translates to:
  /// **'문의가 접수되었습니다. 최대한 빨리 답변 드리겠습니다.'**
  String get inquirySuccess;

  /// No description provided for @suggestions.
  ///
  /// In ko, this message translates to:
  /// **'건의사항'**
  String get suggestions;

  /// No description provided for @noSuggestions.
  ///
  /// In ko, this message translates to:
  /// **'등록된 건의사항이 없습니다.'**
  String get noSuggestions;

  /// No description provided for @noInquiries.
  ///
  /// In ko, this message translates to:
  /// **'등록된 문의가 없습니다.'**
  String get noInquiries;

  /// No description provided for @noNoticesAdmin.
  ///
  /// In ko, this message translates to:
  /// **'등록된 공지사항이 없습니다.'**
  String get noNoticesAdmin;

  /// No description provided for @noTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목 없음'**
  String get noTitle;

  /// No description provided for @anonymous.
  ///
  /// In ko, this message translates to:
  /// **'익명'**
  String get anonymous;

  /// No description provided for @completed.
  ///
  /// In ko, this message translates to:
  /// **'답변완료'**
  String get completed;

  /// No description provided for @pending.
  ///
  /// In ko, this message translates to:
  /// **'대기중'**
  String get pending;

  /// No description provided for @sender.
  ///
  /// In ko, this message translates to:
  /// **'보낸사람'**
  String get sender;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @deleteNotice.
  ///
  /// In ko, this message translates to:
  /// **'공지사항 삭제'**
  String get deleteNotice;

  /// No description provided for @deleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말로 삭제하시겠습니까?'**
  String get deleteConfirm;

  /// No description provided for @notificationFollowTitle.
  ///
  /// In ko, this message translates to:
  /// **'팔로우 알림'**
  String get notificationFollowTitle;

  /// No description provided for @notificationFollowContent.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 회원님을 팔로우하기 시작했습니다.'**
  String notificationFollowContent(Object name);

  /// No description provided for @notificationLikeTitle.
  ///
  /// In ko, this message translates to:
  /// **'도움됨 알림'**
  String get notificationLikeTitle;

  /// No description provided for @notificationLikeContent.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 {storeName} 리뷰를 좋아합니다.'**
  String notificationLikeContent(Object name, Object storeName);

  /// No description provided for @notificationCommentTitle.
  ///
  /// In ko, this message translates to:
  /// **'댓글 알림'**
  String get notificationCommentTitle;

  /// No description provided for @notificationCommentContent.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 댓글을 남겼습니다: {text}'**
  String notificationCommentContent(Object name, Object text);

  /// No description provided for @markAllReadSuccess.
  ///
  /// In ko, this message translates to:
  /// **'모든 알림을 읽음 처리했습니다.'**
  String get markAllReadSuccess;

  /// No description provided for @noBitterReviews.
  ///
  /// In ko, this message translates to:
  /// **'쓴소리 리뷰가 없습니다.'**
  String get noBitterReviews;

  /// No description provided for @inquiryHistory.
  ///
  /// In ko, this message translates to:
  /// **'나의 문의 내역'**
  String get inquiryHistory;

  /// No description provided for @totalViewCount.
  ///
  /// In ko, this message translates to:
  /// **'총 조회수'**
  String get totalViewCount;

  /// No description provided for @termsAndPolicy.
  ///
  /// In ko, this message translates to:
  /// **'약관 및 정책'**
  String get termsAndPolicy;

  /// No description provided for @serviceTerms.
  ///
  /// In ko, this message translates to:
  /// **'서비스 이용약관'**
  String get serviceTerms;

  /// No description provided for @privacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get privacyPolicy;

  /// No description provided for @locationTerms.
  ///
  /// In ko, this message translates to:
  /// **'위치기반 서비스 이용약관'**
  String get locationTerms;

  /// No description provided for @noPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진 없음'**
  String get noPhotos;

  /// No description provided for @viewReview.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 보기'**
  String get viewReview;

  /// No description provided for @writeReview.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 쓰기'**
  String get writeReview;

  /// No description provided for @noStoreInfo.
  ///
  /// In ko, this message translates to:
  /// **'매장 정보가 없습니다.'**
  String get noStoreInfo;

  /// No description provided for @shareExperience.
  ///
  /// In ko, this message translates to:
  /// **'당신의 경험을 공유해주세요'**
  String get shareExperience;

  /// No description provided for @writeFirstReview.
  ///
  /// In ko, this message translates to:
  /// **'첫 리뷰 작성하기'**
  String get writeFirstReview;

  /// No description provided for @regionKorea.
  ///
  /// In ko, this message translates to:
  /// **'대한민국'**
  String get regionKorea;

  /// No description provided for @regionSeoul.
  ///
  /// In ko, this message translates to:
  /// **'서울'**
  String get regionSeoul;

  /// No description provided for @regionBusan.
  ///
  /// In ko, this message translates to:
  /// **'부산'**
  String get regionBusan;

  /// No description provided for @regionDaegu.
  ///
  /// In ko, this message translates to:
  /// **'대구'**
  String get regionDaegu;

  /// No description provided for @regionIncheon.
  ///
  /// In ko, this message translates to:
  /// **'인천'**
  String get regionIncheon;

  /// No description provided for @regionGwangju.
  ///
  /// In ko, this message translates to:
  /// **'광주광역시'**
  String get regionGwangju;

  /// No description provided for @regionDaejeon.
  ///
  /// In ko, this message translates to:
  /// **'대전광역시'**
  String get regionDaejeon;

  /// No description provided for @regionUlsan.
  ///
  /// In ko, this message translates to:
  /// **'울산광역시'**
  String get regionUlsan;

  /// No description provided for @regionSejong.
  ///
  /// In ko, this message translates to:
  /// **'세종특별자치시'**
  String get regionSejong;

  /// No description provided for @regionGyeonggi.
  ///
  /// In ko, this message translates to:
  /// **'경기도'**
  String get regionGyeonggi;

  /// No description provided for @regionGangwon.
  ///
  /// In ko, this message translates to:
  /// **'강원특별자치도'**
  String get regionGangwon;

  /// No description provided for @regionChungbuk.
  ///
  /// In ko, this message translates to:
  /// **'충청북도'**
  String get regionChungbuk;

  /// No description provided for @regionChungnam.
  ///
  /// In ko, this message translates to:
  /// **'충청남도'**
  String get regionChungnam;

  /// No description provided for @regionJeonbuk.
  ///
  /// In ko, this message translates to:
  /// **'전북특별자치도'**
  String get regionJeonbuk;

  /// No description provided for @regionJeonnam.
  ///
  /// In ko, this message translates to:
  /// **'전라남도'**
  String get regionJeonnam;

  /// No description provided for @regionGyeongbuk.
  ///
  /// In ko, this message translates to:
  /// **'경상북도'**
  String get regionGyeongbuk;

  /// No description provided for @regionGyeongnam.
  ///
  /// In ko, this message translates to:
  /// **'경상남도'**
  String get regionGyeongnam;

  /// No description provided for @regionJeju.
  ///
  /// In ko, this message translates to:
  /// **'제주특별자치도'**
  String get regionJeju;

  /// No description provided for @requestStoreRegistration.
  ///
  /// In ko, this message translates to:
  /// **'매장 등록 요청'**
  String get requestStoreRegistration;

  /// No description provided for @storeName.
  ///
  /// In ko, this message translates to:
  /// **'매장명'**
  String get storeName;

  /// No description provided for @storeIntro.
  ///
  /// In ko, this message translates to:
  /// **'소개'**
  String get storeIntro;

  /// No description provided for @storeAddress.
  ///
  /// In ko, this message translates to:
  /// **'주소'**
  String get storeAddress;

  /// No description provided for @storePhone.
  ///
  /// In ko, this message translates to:
  /// **'전화번호'**
  String get storePhone;

  /// No description provided for @storeHours.
  ///
  /// In ko, this message translates to:
  /// **'운영시간'**
  String get storeHours;

  /// No description provided for @storeMenu.
  ///
  /// In ko, this message translates to:
  /// **'추천 메뉴 / 메뉴'**
  String get storeMenu;

  /// No description provided for @submitRequest.
  ///
  /// In ko, this message translates to:
  /// **'요청 보내기'**
  String get submitRequest;

  /// No description provided for @requestSuccess.
  ///
  /// In ko, this message translates to:
  /// **'요청이 성공적으로 접수되었습니다. 검토 후 처리해드리겠습니다.'**
  String get requestSuccess;

  /// No description provided for @openTime.
  ///
  /// In ko, this message translates to:
  /// **'오픈 시간'**
  String get openTime;

  /// No description provided for @closeTime.
  ///
  /// In ko, this message translates to:
  /// **'마감 시간'**
  String get closeTime;

  /// No description provided for @addPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가하기'**
  String get addPhoto;

  /// No description provided for @storePhoto.
  ///
  /// In ko, this message translates to:
  /// **'매장 사진 (1장)'**
  String get storePhoto;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'en',
        'es',
        'id',
        'ja',
        'ko',
        'my',
        'pt',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'my':
      return AppLocalizationsMy();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
