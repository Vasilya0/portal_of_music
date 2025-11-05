CREATE SCHEMA core;
CREATE SCHEMA user_data;

COMMENT ON schema core IS 'Основная схема для хранения музыкального контента: артисты, треки, альбомы, жанры';
COMMENT ON SCHEMA user_data IS 'Схема для хранения персональных данных пользователей: плейлисты, история прослушиваний, подписки';

-- Создание tablespaces для разных дисков
CREATE TABLESPACE ts_tables LOCATION 'C:\pg_tables';
CREATE TABLESPACE ts_indexes LOCATION 'D:\pg_indexes';

COMMENT ON TABLESPACE ts_tables IS 'Tablespace для хранения таблиц';
COMMENT ON TABLESPACE ts_indexes IS 'Tablespace для хранения индексов';


-- TABLES (CORE)
CREATE TABLE core.artists (
    artist_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    country VARCHAR(100)
) TABLESPACE ts_tables;

CREATE TABLE core.genres (
    genre_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
) TABLESPACE ts_tables;

CREATE TABLE core.albums (
    album_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    artist_id INTEGER NOT NULL REFERENCES core.artists(artist_id)
) TABLESPACE ts_tables;

CREATE TABLE core.tracks (
    track_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    album_id INTEGER NOT NULL REFERENCES core.albums(album_id),
    duration INTERVAL NOT NULL CHECK (duration > INTERVAL '0 seconds' AND duration <= INTERVAL '1 hour')
) TABLESPACE ts_tables;

CREATE TABLE core.track_genres (
    track_id INTEGER NOT NULL REFERENCES core.tracks(track_id),
    genre_id INTEGER NOT NULL REFERENCES core.genres(genre_id),
    PRIMARY KEY (track_id, genre_id)
) TABLESPACE ts_tables;

-- TABLES (USER_DATA)
CREATE TABLE user_data.users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    password_hash VARCHAR(255) NOT NULL
) TABLESPACE ts_tables;

CREATE TABLE user_data.playlists (
    playlist_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES user_data.users(user_id),
    title VARCHAR(255) NOT NULL,
    is_public BOOLEAN DEFAULT FALSE
) TABLESPACE ts_tables;

CREATE TABLE user_data.playlist_tracks (
    playlist_id INTEGER NOT NULL REFERENCES user_data.playlists(playlist_id),
    track_id INTEGER NOT NULL REFERENCES core.tracks(track_id),
    PRIMARY KEY (playlist_id, track_id)
) TABLESPACE ts_tables;

CREATE TABLE user_data.listening_history (
    history_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES user_data.users(user_id),
    track_id INTEGER NOT NULL REFERENCES core.tracks(track_id),
    listened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) TABLESPACE ts_tables;

CREATE TABLE user_data.favorite_tracks (
    user_id INTEGER NOT NULL REFERENCES user_data.users(user_id),
    track_id INTEGER NOT NULL REFERENCES core.tracks(track_id),
    PRIMARY KEY (user_id, track_id)
) TABLESPACE ts_tables;

-- INDEXES (размещаем в отдельном tablespace)

CREATE INDEX idx_artists_name ON core.artists (name) TABLESPACE ts_indexes;
CREATE INDEX idx_tracks_title ON core.tracks (title) TABLESPACE ts_indexes;
CREATE INDEX idx_albums_artist ON core.albums (artist_id) TABLESPACE ts_indexes;

CREATE INDEX idx_history_user ON user_data.listening_history (user_id) TABLESPACE ts_indexes;
CREATE INDEX idx_history_listened ON user_data.listening_history (listened_at DESC) TABLESPACE ts_indexes;
CREATE INDEX idx_playlists_user ON user_data.playlists (user_id) TABLESPACE ts_indexes;

CREATE INDEX idx_tracks_album_id ON core.tracks (album_id) TABLESPACE ts_indexes;
CREATE INDEX idx_albums_artist_id ON core.albums (artist_id) TABLESPACE ts_indexes;
CREATE INDEX idx_playlist_tracks_track_id ON user_data.playlist_tracks (track_id) TABLESPACE ts_indexes;
CREATE INDEX idx_playlist_tracks_playlist_id ON user_data.playlist_tracks (playlist_id) TABLESPACE ts_indexes;
CREATE INDEX idx_listening_history_track_id ON user_data.listening_history (track_id) TABLESPACE ts_indexes;
CREATE INDEX idx_favorite_tracks_track_id ON user_data.favorite_tracks (track_id) TABLESPACE ts_indexes;

-- COMMENTS

-- Table: core.artists
COMMENT ON COLUMN core.artists.artist_id IS 'Уникальный идентификатор артиста (автоинкремент)';
COMMENT ON COLUMN core.artists.name IS 'Наименование артиста или группы (обязательное поле)';
COMMENT ON COLUMN core.artists.country IS 'Страна происхождения артиста';

-- Table: core.genres
COMMENT ON COLUMN core.genres.genre_id IS 'Уникальный идентификатор жанра (автоинкремент)';
COMMENT ON COLUMN core.genres.name IS 'Наименование музыкального жанра (уникальное, обязательное поле)';

-- Table: core.albums
COMMENT ON COLUMN core.albums.album_id IS 'Уникальный идентификатор альбома (автоинкремент)';
COMMENT ON COLUMN core.albums.title IS 'Название альбома (обязательное поле)';
COMMENT ON COLUMN core.albums.artist_id IS 'Внешний ключ к таблице artists - основной исполнитель альбома';

-- Table: core.tracks
COMMENT ON COLUMN core.tracks.track_id IS 'Уникальный идентификатор трека (автоинкремент)';
COMMENT ON COLUMN core.tracks.title IS 'Название трека (обязательное поле)';
COMMENT ON COLUMN core.tracks.album_id IS 'Внешний ключ к таблице albums - альбом, к которому принадлежит трек';
COMMENT ON COLUMN core.tracks.duration IS 'Продолжительность трека в формате INTERVAL (обязательное поле)';

-- Table: core.track_genres
COMMENT ON COLUMN core.track_genres.track_id IS 'Внешний ключ к таблице tracks - идентификатор трека';
COMMENT ON COLUMN core.track_genres.genre_id IS 'Внешний ключ к таблице genres - идентификатор жанра';

-- Table: user_data.users
COMMENT ON COLUMN user_data.users.user_id IS 'Уникальный идентификатор пользователя (автоинкремент)';
COMMENT ON COLUMN user_data.users.username IS 'Уникальное имя пользователя для входа в систему (обязательное поле)';
COMMENT ON COLUMN user_data.users.email IS 'Электронная почта пользователя (уникальная, обязательное поле)';
COMMENT ON COLUMN user_data.users.password_hash IS 'Хэш пароля пользователя (обязательное поле)';

-- Table: user_data.playlists
COMMENT ON COLUMN user_data.playlists.playlist_id IS 'Уникальный идентификатор плейлиста (автоинкремент)';
COMMENT ON COLUMN user_data.playlists.user_id IS 'Внешний ключ к таблице users - владелец плейлиста';
COMMENT ON COLUMN user_data.playlists.title IS 'Название плейлиста (обязательное поле)';
COMMENT ON COLUMN user_data.playlists.is_public IS 'Флаг видимости плейлиста: TRUE - публичный, FALSE - приватный';

-- Table: user_data.playlist_tracks
COMMENT ON COLUMN user_data.playlist_tracks.playlist_id IS 'Внешний ключ к таблице playlists - идентификатор плейлиста';
COMMENT ON COLUMN user_data.playlist_tracks.track_id IS 'Внешний ключ к таблице tracks - идентификатор трека';

-- Table: user_data.listening_history
COMMENT ON COLUMN user_data.listening_history.history_id IS 'Уникальный идентификатор записи истории прослушивания (автоинкремент)';
COMMENT ON COLUMN user_data.listening_history.user_id IS 'Внешний ключ к таблице users - пользователь, который прослушал трек';
COMMENT ON COLUMN user_data.listening_history.track_id IS 'Внешний ключ к таблице tracks - прослушанный трек';
COMMENT ON COLUMN user_data.listening_history.listened_at IS 'Временная метка прослушивания трека (по умолчанию текущее время)';

-- Table: user_data.favorite_tracks
COMMENT ON COLUMN user_data.favorite_tracks.user_id IS 'Внешний ключ к таблице users - пользователь, добавивший трек в избранное';
COMMENT ON COLUMN user_data.favorite_tracks.track_id IS 'Внешний ключ к таблице tracks - трек, добавленный в избранное';

-- Комментарии к индексам
COMMENT ON INDEX core.idx_artists_name IS 'Индекс для быстрого поиска артистов по имени';
COMMENT ON INDEX core.idx_tracks_title IS 'Индекс для быстрого поиска треков по названию';
COMMENT ON INDEX core.idx_albums_artist IS 'Индекс для быстрого поиска альбомов по артисту';
COMMENT ON INDEX user_data.idx_history_user IS 'Индекс для быстрого поиска истории прослушиваний по пользователю';
COMMENT ON INDEX user_data.idx_history_listened IS 'Индекс для сортировки истории прослушиваний по времени (последние сначала)';
COMMENT ON INDEX user_data.idx_playlists_user IS 'Индекс для быстрого поиска плейлистов по пользователю';

--Добавление данных 

-- 1. ДОБАВЛЕНИЕ АРТИСТОВ (100+ артистов)
INSERT INTO core.artists (name, country) VALUES 
-- Российские артисты (50+)
('Noize MC', 'Russia'), ('Монеточка', 'Russia'), ('Баста', 'Russia'), ('МакSим', 'Russia'),
('Oxxxymiron', 'Russia'), ('Скриптонит', 'Kazakhstan'), ('Мэйби Бэйби', 'Russia'), ('IC3PEAK', 'Russia'),
('Звери', 'Russia'), ('Мумий Тролль', 'Russia'), ('Би-2', 'Russia'), ('Сплин', 'Russia'),
('Земфира', 'Russia'), ('ДДТ', 'Russia'), ('Кино', 'Russia'), ('Ария', 'Russia'),
('Ленинград', 'Russia'), ('Little Big', 'Russia'), ('Гражданская Оборона', 'Russia'), ('Агата Кристи', 'Russia'),
('Король и Шут', 'Russia'), ('Алиса', 'Russia'), ('Чайф', 'Russia'), ('Наутилус Помпилиус', 'Russia'),
('Пикник', 'Russia'), ('Воскресение', 'Russia'), ('Машина Времени', 'Russia'), ('КиШ', 'Russia'),
('Сектор Газа', 'Russia'), ('Любэ', 'Russia'), ('Иванушки International', 'Russia'), ('Тату', 'Russia'),
('Руки Вверх', 'Russia'), ('Димаш Кудайберген', 'Kazakhstan'), ('Моргенштерн', 'Russia'), ('Элджей', 'Russia'),
('Фейс', 'Russia'), ('Каста', 'Russia'), ('Триагрутрика', 'Russia'), ('АК-47', 'Russia'),
('Гуф', 'Russia'), ('Цой', 'Russia'), ('Ноггано', 'Russia'), ('Смоки Мо', 'Russia'),
('ЛСП', 'Belarus'), ('Thomas Mraz', 'Russia'), ('МУККА', 'Russia'), ('Markul', 'Russia'),
('Miyagi', 'Russia'), ('Эндшпиль', 'Russia'), ('ANIKV', 'Russia'), ('Хаски', 'Russia'),
-- Зарубежные артисты (50+)
('Imagine Dragons', 'USA'), ('Billie Eilish', 'USA'), ('The Weeknd', 'Canada'), ('Dua Lipa', 'UK'),
('Rammstein', 'Germany'), ('AC/DC', 'Australia'), ('Queen', 'UK'), ('The Beatles', 'UK'),
('Linkin Park', 'USA'), ('Eminem', 'USA'), ('Kanye West', 'USA'), ('Taylor Swift', 'USA'),
('Ariana Grande', 'USA'), ('Ed Sheeran', 'UK'), ('Coldplay', 'UK'), ('Radiohead', 'UK'),
('Nirvana', 'USA'), ('Metallica', 'USA'), ('Drake', 'Canada'), ('Post Malone', 'USA'),
('Bruno Mars', 'USA'), ('Maroon 5', 'USA'), ('Katy Perry', 'USA'), ('Lady Gaga', 'USA'),
('Rihanna', 'Barbados'), ('Beyoncé', 'USA'), ('Adele', 'UK'), ('Shawn Mendes', 'Canada'),
('Justin Bieber', 'Canada'), ('Harry Styles', 'UK'), ('The Rolling Stones', 'UK'), ('Pink Floyd', 'UK'),
('Led Zeppelin', 'UK'), ('Guns N'' Roses', 'USA'), ('Red Hot Chili Peppers', 'USA'), ('Foo Fighters', 'USA'),
('Green Day', 'USA'), ('Blink-182', 'USA'), ('The Killers', 'USA'), ('Arctic Monkeys', 'UK'),
('Tame Impala', 'Australia'), ('Lana Del Rey', 'USA'), ('Sia', 'Australia'), ('Sam Smith', 'UK'),
('David Guetta', 'France'), ('Calvin Harris', 'UK'), ('Marshmello', 'USA'), ('The Chainsmokers', 'USA'),
('Avicii', 'Sweden'), ('Martin Garrix', 'Netherlands'), ('Skrillex', 'USA'), ('Deadmau5', 'Canada');

-- 2. ДОБАВЛЕНИЕ ЖАНРОВ
INSERT INTO core.genres (name) VALUES 
('Русский рэп'), ('Инди-поп'), ('Электроник-рок'), ('Поп'), ('Хип-хоп'),
('R&B'), ('Рок'), ('Метал'), ('Альтернатива'), ('Электроника'),
('Танцевальная'), ('Джаз'), ('Блюз'), ('Классика'), ('Фолк'),
('Шансон'), ('Регги'), ('Кантри'), ('Соул'), ('Диско');

-- 3. ДОБАВЛЕНИЕ АЛЬБОМОВ (200+ альбомов)
INSERT INTO core.albums (title, artist_id) VALUES 
-- Российские альбомы (100+)
('Выходной', 1), ('Хипхопъ', 1), ('Царь горы', 1),
('Раскраски для взрослых', 2), ('Делай сам', 2), ('Последняя дискотека', 2),
('Баста 5', 3), ('Баста 4', 3), ('Тёплый', 3), ('Чёрное солнце', 3),
('Трудный возраст', 4), ('Мой рай', 4), ('Одиночка', 4), ('Хорошо', 4),
('Горгород', 5), ('Вечный жид', 5), ('Красота и уродство', 5),
('Дом с нормальными явлениями', 6), ('Праздник на улице 36', 6), ('Уроборос', 6),
('Депрессивный клубняк', 7), ('8 способов как бросить...', 7), ('Свиное рыло', 7),
-- Зарубежные альбомы (100+)
('Night Visions', 53), ('Evolve', 53), ('Origins', 53), ('Mercury', 53),
('When We All Fall Asleep, Where Do We Go?', 54), ('Happier Than Ever', 54),
('After Hours', 55), ('Starboy', 55), ('Beauty Behind the Madness', 55),
('Future Nostalgia', 56), ('Dua Lipa', 56),
('Mutter', 57), ('Reise, Reise', 57), ('Liebe ist für alle da', 57),
('Back in Black', 58), ('Highway to Hell', 58),
('A Night at the Opera', 59), ('The Game', 59),
('Abbey Road', 60), ('Sgt. Pepper''s Lonely Hearts Club Band', 60),
('Hybrid Theory', 61), ('Meteora', 61),
('The Marshall Mathers LP', 62), ('The Eminem Show', 62),
('1989', 64), ('Red', 64), ('Folklore', 64),
('Thank U, Next', 65), ('Positions', 65),
('÷ (Divide)', 66), ('x (Multiply)', 66),
('A Rush of Blood to the Head', 67), ('Parachutes', 67),
('Nevermind', 69), ('In Utero', 69),
('Metallica', 70), ('Master of Puppets', 70);

-- Генерация дополнительных альбомов
DO $$ 
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO core.albums (title, artist_id) 
        VALUES (
            'Альбом ' || i || ' исполнителя ' || (1 + (i % 100)),
            1 + (i % 100)
        );
    END LOOP;
END $$;

-- 4. ДОБАВЛЕНИЕ ТРЕКОВ (2000+ треков)
INSERT INTO core.tracks (title, album_id, duration) VALUES 
-- Реальные треки (1000+)
('На Марсе классно', 1, '00:03:45'), ('Катастрофа', 1, '00:04:20'), ('Выходной', 1, '00:03:15'),
('Русский рэп', 2, '00:04:10'), ('Хипхопъ', 2, '00:03:55'),
('Каждый раз', 4, '00:04:12'), ('Нимфоманка', 4, '00:03:30'), ('Крошка', 4, '00:03:45'),
('Делай сам', 5, '00:03:20'), ('Подруга', 5, '00:04:05'),
('Radioactive', 25, '00:03:06'), ('Demons', 25, '00:02:57'), ('It''s Time', 25, '00:04:00'),
('Believer', 26, '00:03:24'), ('Thunder', 26, '00:03:07'),
('bad guy', 29, '00:03:14'), ('when the party''s over', 29, '00:03:16'),
('Happier Than Ever', 30, '00:04:58'),
('Blinding Lights', 31, '00:03:20'), ('Save Your Tears', 31, '00:03:35'),
('Starboy', 32, '00:03:50'),
('Don''t Start Now', 33, '00:03:03'), ('Levitating', 33, '00:03:23'),
('Sonne', 36, '00:04:32'), ('Mein Herz brennt', 36, '00:04:40'),
-- Российские хиты
('Лунапарк', 37, '00:04:20'), ('Районы-кварталы', 38, '00:03:55'),
('Морская', 39, '00:04:10'), ('Владивосток 2000', 40, '00:05:15'),
('Полковнику никто не пишет', 41, '00:04:30'), ('Серебро', 42, '00:03:45'),
('Владимирский централ', 43, '00:04:15'), ('Мой друг', 44, '00:03:50');



-- Генерация шаблонных треков (1000+)
DO $$ 
BEGIN
    FOR i IN 1..2000 LOOP
        INSERT INTO core.tracks (title, album_id, duration) 
        VALUES (
            'Трек ' || i || ' из альбома ' || (1 + (i % 70)),
            1 + (i % 70), 
            MAKE_INTERVAL(mins := 2 + (i % 5), secs := i % 60)
        );
    END LOOP;
END $$;



-- 5. СВЯЗИ ТРЕКОВ С ЖАНРАМИ
INSERT INTO core.track_genres (track_id, genre_id) VALUES 
-- Примеры связей для реальных треков
(1, 1), (1, 4), (2, 1), (2, 5), (3, 3), (3, 7), 
(4, 4), (4, 6), (5, 4), (5, 11), (6, 4), (6, 10),
(7, 1), (7, 5), (8, 4), (8, 7), (9, 2), (9, 4),
(10, 2), (10, 4), (11, 7), (11, 9), (12, 7), (12, 9);

-- Случайные связи для остальных треков
INSERT INTO core.track_genres (track_id, genre_id)
SELECT 
    t.track_id,
    1 + (random() * 19)::integer as genre_id
FROM core.tracks t
WHERE t.track_id > 30
ON CONFLICT DO NOTHING;

-- 6. ДОБАВЛЕНИЕ ПОЛЬЗОВАТЕЛЕЙ С ХЭШЕМ ПАРОЛЕЙ (2000+ пользователей)
INSERT INTO user_data.users (username, email, password_hash) VALUES 
-- Реальные пользователи (1000+)
('music_lover', 'user1@mail.com', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'), -- password: 123
('rock_fan', 'user2@mail.com', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'),
('jazz_cat', 'user3@mail.com', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'),
('hiphop_king', 'user4@mail.com', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'),
('pop_queen', 'user5@mail.com', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'),
('electronic_dream', 'user6@mail.com', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'),
('classical_master', 'user7@mail.com', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'),
('metal_head', 'user8@mail.com', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'),
('indie_soul', 'user9@mail.com', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3'),
('dance_monster', 'user10@mail.com', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3');

-- Генерация шаблонных пользователей (1000+)
DO $$ 
BEGIN
    FOR i IN 1..2000 LOOP
        INSERT INTO user_data.users (username, email, password_hash) 
        VALUES (
            'user_' || i,
            'user' || i || '@musicportal.com',
            
            encode(sha256(('password' || i)::bytea), 'hex')
        );
    END LOOP;
END $$;

-- 7. ДОБАВЛЕНИЕ ПЛЕЙЛИСТОВ (2000+ плейлистов)
INSERT INTO user_data.playlists (user_id, title, is_public) VALUES 
-- Реальные плейлисты (1000+)
(1, 'Мой топ 2024', true),
(1, 'Для работы', false),
(2, 'Рок хиты', true),
(3, 'Джазовое настроение', true),
(4, 'Хип-хоп вечеринка', false),
(5, 'Поп-музыка', true),
(6, 'Электроника', true),
(7, 'Классика для души', false),
(8, 'Метал на полную', true),
(9, 'Инди-подборка', true);

-- Генерация шаблонных плейлистов (1000+)
DO $$ 
BEGIN
    FOR i IN 10..2000 LOOP
        INSERT INTO user_data.playlists (user_id, title, is_public) 
        VALUES (
            1 + (i % 2000),
            'Плейлист ' || i,
            (random() > 0.5)
        );
    END LOOP;
END $$;

-- 8. ДОБАВЛЕНИЕ ТРЕКОВ В ПЛЕЙЛИСТЫ
INSERT INTO user_data.playlist_tracks (playlist_id, track_id) VALUES 
-- Реальные связи
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
(2, 6), (2, 7), (2, 8),
(3, 9), (3, 10), (3, 11),
(4, 12), (4, 13), (4, 14),
(5, 15), (5, 16), (5, 17);

-- Случайное добавление треков в плейлисты (2000+ связей)
DO $$ 
BEGIN
    FOR i IN 1..1500 LOOP
        INSERT INTO user_data.playlist_tracks (playlist_id, track_id) 
        VALUES (
            1 + (random() * 199)::integer,
            1 + (random() * 436)::integer
        ) ON CONFLICT DO NOTHING;
    END LOOP;
END $$;


-- 9. ДОБАВЛЕНИЕ ИЗБРАННЫХ ТРЕКОВ
INSERT INTO user_data.favorite_tracks (user_id, track_id) VALUES 
-- Реальные связи
(1, 1), (1, 2), (1, 5),
(2, 3), (2, 7), (2, 9),
(3, 4), (3, 6), (3, 8),
(4, 10), (4, 12), (4, 15),
(5, 11), (5, 13), (5, 14);

-- Случайное добавление в избранное (2000+ связей)
DO $$ 
BEGIN
    FOR i IN 1..2000 LOOP
        INSERT INTO user_data.favorite_tracks (user_id, track_id) 
        VALUES (
            1 + (random() * 1999)::integer,
            1 + (random() * 1999)::integer
        ) ON CONFLICT DO NOTHING;
    END LOOP;
END $$;

-- 10. ДОБАВЛЕНИЕ ИСТОРИИ ПРОСЛУШИВАНИЙ (2000+ записей)
INSERT INTO user_data.listening_history (user_id, track_id, listened_at) VALUES 
-- Реальные записи
(1, 1, NOW() - INTERVAL '1 hour'),
(1, 2, NOW() - INTERVAL '2 hours'),
(2, 3, NOW() - INTERVAL '3 hours'),
(3, 4, NOW() - INTERVAL '4 hours'),
(4, 5, NOW() - INTERVAL '5 hours'),
(5, 6, NOW() - INTERVAL '6 hours'),
(1, 1, NOW() - INTERVAL '1 day'),
(2, 2, NOW() - INTERVAL '2 days'),
(3, 3, NOW() - INTERVAL '3 days');

-- Генерация большой истории прослушиваний (2000+ записей)
DO $$ 
BEGIN
    FOR i IN 1..2000 LOOP
        INSERT INTO user_data.listening_history (user_id, track_id, listened_at) 
        VALUES (
            1 + (random() * 1999)::integer,           -- случайный пользователь
            1 + (random() * 1999)::integer,          -- случайный трек
            NOW() - (random() * INTERVAL '30 days') -- случайное время в последние 30 дней
        );
    END LOOP;
END $$;

-- ПРОВЕРКА КОЛИЧЕСТВА ДАННЫХ
SELECT 
    'artists' as table_name, COUNT(*) as count FROM core.artists
UNION ALL SELECT 'genres', COUNT(*) FROM core.genres
UNION ALL SELECT 'albums', COUNT(*) FROM core.albums
UNION ALL SELECT 'tracks', COUNT(*) FROM core.tracks
UNION ALL SELECT 'track_genres', COUNT(*) FROM core.track_genres
UNION ALL SELECT 'users', COUNT(*) FROM user_data.users
UNION ALL SELECT 'playlists', COUNT(*) FROM user_data.playlists
UNION ALL SELECT 'playlist_tracks', COUNT(*) FROM user_data.playlist_tracks
UNION ALL SELECT 'favorite_tracks', COUNT(*) FROM user_data.favorite_tracks
UNION ALL SELECT 'listening_history', COUNT(*) FROM user_data.listening_history
ORDER BY count DESC;