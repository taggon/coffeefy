# Coffeefy

스타벅스 Wifi에 자동으로 접속해주는 맥 애플리케이션입니다.

![coffeefy](https://cloud.githubusercontent.com/assets/212034/21880524/cb20e8aa-d8e2-11e6-90c3-9c7f4d986373.gif)

## 사용법

1. 터미널에서 다음 명령어를 실행하여 Wifi에 로그인하면 나타나는 Captive Network Assistant를 끕니다.

  ```
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -boolean false
  ```

  리부팅하여 위 설정을 적용합니다. Coffeefy를 사용하지 않는다면 위 명령어에서 마지막 `false`만 `true`로 바꿔서 실행한 후 리부팅하면 다시 원래 상태로 되돌아갑니다.

2. Coffeefy를 실행합니다. 메뉴바에서 Coffeefy 아이콘을 클릭한 후 환경설정에 들어가서 로그인 정보를 입력해줍니다. 현재까지는 전화번호와 통신사를 생략해도 잘 동작합니다.

3. 이제 스타벅스로 갑니다. 정상적으로 접속 인증이 되었다면 접속이 잘 되었다는 메시지를 볼 수 있습니다. 

