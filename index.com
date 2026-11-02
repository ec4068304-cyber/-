<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, orientation=landscape">
    <title>Web Roblox Clone & Studio</title>
    <!-- Бесплатная сетевая библиотека PeerJS -->
    <script src="https://unpkg.com"></script>
    <style>
        * { box-sizing: border-box; font-family: 'Segoe UI', sans-serif; margin: 0; padding: 0; user-select: none; touch-action: none; }
        
        body { 
            background: #18181c; 
            color: #fff; 
            width: 100vw; 
            height: 100vh; 
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }

        /* Предупреждение о повороте экрана */
        @media orientation: portrait {
            #rotate-warning { display: flex !important; }
        }
        #rotate-warning {
            position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
            background: #111; z-index: 9999; display: none;
            flex-direction: column; align-items: center; justify-content: center; text-align: center; padding: 20px;
        }

        /* Главный интерфейс */
        #main-container { display: flex; flex: 1; height: calc(100vh - 50px); position: relative; }
        
        /* Вкладки (Экраны) */
        .screen { display: none; width: 100%; height: 100%; padding: 15px; overflow-y: auto; }
        .screen.active { display: flex; }

        /* Нижнее меню навигации */
        #nav-bar { 
            height: 50px; background: #222228; border-top: 2px solid #333;
            display: flex; justify-content: space-around; align-items: center;
        }
        .nav-btn { 
            background: none; border: none; color: #aaa; font-size: 14px; 
            font-weight: bold; cursor: pointer; padding: 10px; transition: 0.2s;
        }
        .nav-btn.active { color: #3498db; border-bottom: 3px solid #3498db; }

        /* ЭКРАН 1: РЕГИСТРАЦИЯ И ВХОД */
        #screen-auth { flex-direction: column; align-items: center; justify-content: center; gap: 15px; }
        .auth-box { background: #2c2c35; padding: 20px; border-radius: 12px; display: flex; flex-direction: column; gap: 10px; width: 300px; box-shadow: 0 4px 15px rgba(0,0,0,0.5); }
        .auth-box input, .auth-box button { padding: 10px; border-radius: 6px; border: none; font-size: 14px; }
        .auth-box input { background: #1e1e24; color: #fff; }
        .auth-box button { background: #3498db; color: #fff; font-weight: bold; cursor: pointer; }

        /* ЭКРАН 2: СКИHЫ И КАСТОМИЗАЦИЯ */
        #screen-avatar { gap: 20px; }
        .avatar-preview-box { flex: 1; background: #25252b; border-radius: 12px; display: flex; align-items: center; justify-content: center; position: relative; }
        .avatar-svg-container { width: 120px; height: 160px; }
        .avatar-customizer { flex: 1.5; background: #2c2c35; border-radius: 12px; padding: 15px; display: flex; flex-direction: column; gap: 15px; }
        .color-pickers { display: flex; gap: 10px; align-items: center; }
        .color-circle { width: 30px; height: 30px; border-radius: 50%; border: 2px solid #fff; cursor: pointer; }
        .item-creator { border-top: 1px solid #444; padding-top: 10px; display: flex; flex-direction: column; gap: 8px; }
        .item-creator input { padding: 6px; background: #1e1e24; border: none; color: white; border-radius: 4px; }

        /* ЭКРАН 3: ЧАТ И СЕТЬ */
        #screen-chat { flex-direction: column; gap: 10px; }
        .chat-messages { flex: 1; background: #1e1e24; border-radius: 8px; padding: 10px; overflow-y: auto; display: flex; flex-direction: column; gap: 5px; }
        .chat-input-area { display: flex; gap: 10px; }
        .chat-input-area input { flex: 1; padding: 10px; background: #2c2c35; border: none; color: white; border-radius: 6px; }
        .chat-input-area button { padding: 10px 20px; background: #2ecc71; border: none; color: white; border-radius: 6px; font-weight: bold; }

        /* ЭКРАН 4: ИГРЫ И МЕЙКЕР */
        #screen-games { gap: 20px; }
        .games-list { flex: 1; background: #25252b; border-radius: 12px; padding: 15px; display: flex; flex-direction: column; gap: 10px; }
        .game-item-card { background: #34495e; padding: 10px; border-radius: 8px; display: flex; justify-content: space-between; align-items: center; }
        .studio-panel { flex: 1.5; background: #2c2c35; border-radius: 12px; padding: 15px; display: flex; flex-direction: column; gap: 10px; }
        .tools-row { display: flex; gap: 8px; }
        .tool-btn { padding: 6px 12px; background: #7f8c8d; border: none; color: white; border-radius: 4px; font-weight: bold; }
        .tool-btn.active { background: #e67e22; }

        /* ИГРОВОЙ ЭКРАН (ИНЛАЙН ПЛЕЙЕР) */
        #game-player-screen {
            position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
            background: #2c3e50; z-index: 1000; display: none; flex-direction: column;
        }
        #gameCanvas { background: #34495e; width: 100%; height: 100%; }
        #close-game-btn { position: absolute; top: 10px; right: 10px; background: #e74c3c; border: none; color: white; padding: 8px 15px; border-radius: 6px; font-weight: bold; z-index: 1001; }
        
        /* Мобильный джойстик поверх игры */
        .game-ui-controls {
            position: absolute; bottom: 15px; left: 0; width: 100%;
            display: flex; justify-content: space-between; padding: 0 30px; pointer-events: none;
        }
        .joy-btn {
            width: 65px; height: 65px; background: rgba(255,255,255,0.8); color: #333;
            border-radius: 50%; display: flex; align-items: center; justify-content: center;
            font-size: 24px; font-weight: bold; pointer-events: auto; box-shadow: 0 4px rgba(0,0,0,0.3);
        }
        .joy-btn:active { transform: translateY(3px); box-shadow: none; }
    </style>
</head>
<body>

    <!-- Заглушка переворота -->
    <div id="rotate-warning">
        <h2>🔄 Пожалуйста, переверните устройство!</h2>
        <p style="color: #aaa; margin-top: 10px;">Для создания и игры в Роблокс необходим горизонтальный режим (альбомный).</p>
    </div>

    <!-- Основной контейнер окон -->
    <div id="main-container">
        
        <!-- ЭКРАН 1: АВТОРИЗАЦИЯ -->
        <div id="screen-auth" class="screen active">
            <div class="auth-box" id="auth-form">
                <h3 style="text-align: center;" id="auth-title">Вход в WebRoblox</h3>
                <input type="text" id="username" placeholder="Ваш никнейм">
                <input type="password" id="password" placeholder="Пароль">
                <button id="auth-submit-btn">Войти / Создать</button>
                <div id="auth-status" style="font-size:12px; text-align:center; color:#2ecc71;"></div>
            </div>
        </div>

        <!-- ЭКРАН 2: АВАТАР И СКИНЫ -->
        <div id="screen-avatar" class="screen">
            <div class="avatar-preview-box">
                <h4 style="position:absolute; top:10px; left:10px;">Ваш Персонаж</h4>
                <!-- Простая SVG кукла челика -->
                <svg class="avatar-svg-container" viewBox="0 0 100 130">
                    <circle id="char-head" cx="50" cy="25" r="15" fill="#f39c12"/>
                    <rect id="char-body" x="30" y="45" width="40" height="50" rx="5" fill="#3498db"/>
                    <rect id="char-hat" x="25" y="5" width="50" height="8" rx="2" fill="none"/>
                    <rect id="char-hat-top" x="35" y="-3" width="30" height="8" rx="2" fill="none"/>
                </svg>
            </div>
            <div class="avatar-customizer">
                <h3>Кастомизация</h3>
                <div>
                    <label>Цвет кожи:</label>
                    <div class="color-pickers">
                        <div class="color-circle" style="background:#f39c12;" onclick="changeSkin('#f39c12')"></div>
                        <div class="color-circle" style="background:#ffdbac;" onclick="changeSkin('#ffdbac')"></div>
                        <div class="color-circle" style="background:#e0ac69;" onclick="changeSkin('#e0ac69')"></div>
                    </div>
                </div>
                <div>
                    <label>Цвет одежды:</label>
                    <div class="color-pickers">
                        <div class="color-circle" style="background:#3498db;" onclick="changeClothes('#3498db')"></div>
                        <div class="color-circle" style="background:#e74c3c;" onclick="changeClothes('#e74c3c')"></div>
                        <div class="color-circle" style="background:#2ecc71;" onclick="changeClothes('#2ecc71')"></div>
                    </div>
                </div>
                <div class="item-creator">
                    <h4>Создать вещь (Шляпа)</h4>
                    <div style="display:flex; gap:10px;">
                        <input type="color" id="hat-color-input" value="#e67e22">
                        <button onclick="applyCustomHat()" style="padding:5px 10px; background:#9b59b6; border:none; color:white; border-radius:4px;">Надеть шляпу</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- ЭКРАН 3: ЧАТ И СЕТЬ -->
        <div id="screen-chat" class="screen">
            <div class="net-box" style="margin:0;">
                Ваш Сетевой ID: <span id="my-peer-id" style="color:#f1c40f; font-weight:bold;">Подключение...</span> | 
                Подключиться к другу: <input type="text" id="friend-id" placeholder="ID друга" style="padding:2px; width:120px;">
                <button onclick="connectToFriend()" style="padding:2px 10px; background:#3498db; border:none; color:white;">ОК</button>
            </div>
            <div class="chat-messages" id="chat-box">
