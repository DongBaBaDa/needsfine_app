import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_my.dart';

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
    Locale('en'),
    Locale('id'),
    Locale('ko'),
    Locale('my')
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
  /// **'니즈파인'**
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
  /// **'평균 니즈파인 점수'**
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
  /// **'매장 순위'**
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
  /// **'정보 없음'**
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
  /// **'정보를 불러올 수 없습니다.'**
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
  /// **'사용자의 리뷰를 통해 다른 사용자가 느끼는 해당 매장의 느낌을 수치화한 점수'**
  String get scoreDesc;

  /// No description provided for @waitingSpot.
  ///
  /// In ko, this message translates to:
  /// **'웨이팅 맛집'**
  String get waitingSpot;

  /// No description provided for @localSpot.
  ///
  /// In ko, this message translates to:
  /// **'지역 맛집'**
  String get localSpot;

  /// No description provided for @goodSpot.
  ///
  /// In ko, this message translates to:
  /// **'맛있는 식당'**
  String get goodSpot;

  /// No description provided for @polarizingSpot.
  ///
  /// In ko, this message translates to:
  /// **'호불호 있는 식당'**
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
  /// **'지도로 이동합니다.'**
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

  /// No description provided for @unknownUser.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 유저'**
  String get unknownUser;

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

  /// No description provided for @startFollowingMessage.
  ///
  /// In ko, this message translates to:
  /// **'{name}님을 팔로우합니다.'**
  String startFollowingMessage(Object name);

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
  /// **'이메일과 비밀번호를 입력해주세요.'**
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
  /// **'맛집, 지역, 키워드 검색'**
  String get searchPlaceholder;

  /// No description provided for @realTimeBestReviews.
  ///
  /// In ko, this message translates to:
  /// **'실시간 베스트 리뷰 🏆'**
  String get realTimeBestReviews;

  /// No description provided for @imagePreparing.
  ///
  /// In ko, this message translates to:
  /// **'이미지 준비중'**
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
  /// **'등록된 이미지가 없습니다.'**
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
  /// **'닉네임을 입력해주세요.'**
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
  /// **'사용 가능한 닉네임입니다.'**
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
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id', 'ko', 'my'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'ko':
      return AppLocalizationsKo();
    case 'my':
      return AppLocalizationsMy();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
