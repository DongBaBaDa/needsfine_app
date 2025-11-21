import 'package:flutter/material.dart';
import 'dart:math';

// 1. 리뷰 모델
class Review {
  final String userName;
  final String content;
  final double rating;
  final double qrScore; // 리뷰 퀄리티 점수 (파이썬 로직)
  final String date;

  Review({
    required this.userName,
    required this.content,
    required this.rating,
    required this.qrScore,
    required this.date,
  });
}

// 2. 가게 모델
class Store {
  final String id;
  final String name;
  final String category;
  final List<String> tags; // 매장 등록 태그
  double userRating; // 별점
  double needsFineScore; // 니즈파인 지수
  int reviewCount;
  List<Review> reviews;

  Store({
    required this.id,
    required this.name,
    required this.category,
    required this.tags,
    this.userRating = 0.0,
    this.needsFineScore = 0.0,
    this.reviewCount = 0,
    required this.reviews,
  });
}

// 3. [전역 데이터] - 앱 끄면 사라지지만 실행 중엔 유지됨 (DB 역할)
class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  // 더미 가게 데이터 (엑셀 대신 사용)
  List<Store> stores = [
    Store(
      id: '1',
      name: "족발야시장 강남점",
      category: "족발·보쌈",
      tags: ["맛있는", "친절한", "푸짐한", "깨끗한", "가성비"],
      userRating: 4.5,
      needsFineScore: 88.5,
      reviewCount: 120,
      reviews: [],
    ),
    Store(
      id: '2',
      name: "엽기떡볶이 본점",
      category: "분식",
      tags: ["매운", "스트레스", "중독성", "빠른", "배달"],
      userRating: 4.8,
      needsFineScore: 92.0,
      reviewCount: 350,
      reviews: [],
    ),
  ];

  // 내 리뷰 모음
  List<Map<String, dynamic>> myReviews = [];

  // --- [🔥 파이썬 로직 이식: 리뷰 등록 및 점수 계산] ---
  void addReview(String storeId, String content, double rating) {
    Store? store = stores.firstWhere((s) => s.id == storeId);

    // 1. 리뷰 퀄리티(Q_R) 계산 (파이썬 로직 단순화)
    double qrScore = _calculateQR(content, store.tags);

    // 2. 리뷰 추가
    Review newReview = Review(
      userName: "니즈파인", // 현재 로그인한 유저
      content: content,
      rating: rating,
      qrScore: qrScore,
      date: DateTime.now().toString().split(' ')[0],
    );
    store.reviews.insert(0, newReview);
    store.reviewCount++;

    // 3. 내 리뷰 목록에도 추가
    myReviews.insert(0, {
      "storeName": store.name,
      "content": content,
      "rating": rating,
      "date": newReview.date,
    });

    // 4. 가게 점수(별점, 니즈파인 지수) 업데이트
    _updateStoreScores(store);
  }

  // (파이썬 calculate_q_r 함수 Dart 버전)
  double _calculateQR(String text, List<String> storeTags) {
    double score = 0;
    int len = text.length;

    // 길이 점수
    if (len < 10) score += 0.1;
    else if (len > 100) score += 1.0;
    else score += 0.5;

    // 태그 일치 보너스 (단순 매칭)
    int matchCount = 0;
    for (var tag in storeTags) {
      if (text.contains(tag)) matchCount++;
    }
    score += (0.5 * matchCount);

    return score;
  }

  // 점수 업데이트 로직
  void _updateStoreScores(Store store) {
    // 1. 별점 평균 재계산
    double totalRating = 0;
    double totalQR = 0;
    for (var r in store.reviews) {
      totalRating += r.rating;
      totalQR += r.qrScore;
    }
    store.userRating = totalRating / store.reviewCount;

    // 2. 니즈파인 지수 계산 (파이썬 공식 참고)
    // 신뢰도 총점 = 기본(0.5) + 리뷰퀄리티(로그함수 대체 정규화) + 매칭(생략)
    double avgQR = totalQR / store.reviewCount;
    double trustScore = 0.5 + (avgQR * 0.2); // 약식 공식
    if (trustScore > 1.0) trustScore = 1.0;

    // 최종 니즈파인 지수 (별점 * 신뢰도 * 20 -> 100점 만점 환산)
    store.needsFineScore = (store.userRating * trustScore) * 20;
    // 보기 좋게 100점 안 넘게 조정
    if (store.needsFineScore > 99.9) store.needsFineScore = 99.9;
  }
}