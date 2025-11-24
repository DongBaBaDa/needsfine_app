"use client";

import { Button } from "@/components/ui/button";

export default function MainHero() {
    return (
        <div className="w-full bg-white text-black">
            {/* NAVIGATION */}
            <nav className="w-full flex items-center justify-between px-6 md:px-12 py-5 border-b border-gray-200">
                <h1 className="text-2xl font-semibold tracking-tight">NeedsFine</h1>

                <div className="hidden md:flex gap-10 text-base font-medium">
                    <a href="/store-join" className="hover:text-gray-600 transition">사장님 입점</a>
                    <a href="/brand-story" className="hover:text-gray-600 transition">브랜드 스토리</a>
                </div>

                <Button
                    onClick={() => (window.location.href = "/download")}
                    className="bg-blue-500 text-white font-semibold hover:bg-blue-600 px-4 py-2 text-sm md:text-base"
                >
                    앱 다운로드
                </Button>
            </nav>

            {/* MAIN HERO SECTION */}
            <section className="w-full flex flex-col items-start justify-center px-6 md:px-24 py-24 min-h-[60vh]">
                <p className="text-lg md:text-2xl mb-3 text-gray-700">가짜 리뷰 없는 세상</p>

                <h2 className="text-4xl md:text-6xl font-extrabold leading-tight mb-4">
                    신뢰만 남기는<br className="hidden md:block" />
                    맛집 검증 플랫폼
                </h2>

                <p className="text-base md:text-xl text-gray-500 mb-10 max-w-xl">
                    후회 없는 선택. 어뷰징 없는 진짜 리뷰. 니즈파인이 검증해서 보여드립니다.
                </p>

                <Button
                    onClick={() => (window.location.href = "/download")}
                    className="bg-black text-white text-lg md:text-xl hover:bg-gray-800 px-10 py-4 rounded-lg"
                >
                    시작하기
                </Button>
            </section>
        </div>
    );
}
