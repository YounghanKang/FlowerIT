# 💐 FlowerIT

> AIoT 기술로 시들어가는 꽃의 시간을 되돌려, 아름다움을 더 오래 간직하도록 돕습니다.

FlowerIT는 인공지능(AI)과 사물인터넷(IoT)을 결합하여, **절화(잘라낸 꽃)**의 상태를 실시간으로 분석하고 관리하는 스마트 시스템입니다.

<br/>

## ✨ 주요 기능 (Features)

-   **🤖 AI 상태 분석:** 주기적으로 촬영된 꽃 사진을 AI 모델이 분석하여 '건강함', '시들고 있음' 등 현재 상태를 정확히 알려줍니다.
-   **📱 실시간 원격 모니터링:** 언제 어디서든 스마트폰 앱으로 내 꽃의 최신 사진, 온도, AI 분석 결과를 한눈에 확인할 수 있습니다.
-   **📸 자동 데이터 수집:** 라즈베리파이 기기가 설정된 시간에 맞춰 자동으로 온도를 측정하고 사진을 촬영하여 서버로 전송합니다.
-   **🔗 간편한 QR 코드 연동:** 복잡한 설정 없이, 앱 화면에 나타난 QR 코드를 라즈베리파이 카메라로 스캔하는 것만으로 기기 연결이 완료됩니다.

<br/>

## 🛠️ 기술 스택 (Tech Stack)

| Category              | Techs                                                              |
| --------------------- | ------------------------------------------------------------------ |
| **📱 Mobile App** | `Dart`, `Flutter`                                                  |
| **🤖 AI / ML** | `Python`, `TensorFlow Lite`                                        |
| **☁️ Backend & Server** | `Flask`, `Google Firebase` (Firestore, Authentication, Storage)    |
| **🔌 IoT & Hardware** | `Raspberry Pi 5`, `libcamera`, `DS18B20 Temperature Sensor`          |

<br/>

## 📱 실행 화면 (Screenshots)

<br/>

## 🚀 앞으로의 개발 계획 (Future Works)

-   [ ] 수위 센서를 연동하여 물 부족 시 자동 급수 알림 기능 추가
-   [ ] AI 모델을 고도화하여 특정 질병 예측 기능 개발
-   [ ] 꽃의 종류에 따른 최적 관리 가이드(온도, 물 교체 주기 등) 제공
-   [ ] 수집된 데이터를 시각화하여 상태 변화 그래프 표시

<br/>

---

**Project by YounghanKang** ([GitHub Profile](https://github.com/YounghanKang))