PGDMP  )    	                |            LibraryDataBase    17.0    17.0 T    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false            �           1262    73729    LibraryDataBase    DATABASE     �   CREATE DATABASE "LibraryDataBase" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';
 !   DROP DATABASE "LibraryDataBase";
                     postgres    false                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
                     pg_database_owner    false            �           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                        pg_database_owner    false    6            B           1255    81923    add_available_copies()    FUNCTION     �  CREATE FUNCTION public.add_available_copies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 IF (OLD.book_status = 'активно' AND NEW.book_status = 'возвращено') or (OLD.book_status = 'зарезервировано' AND NEW.book_status = 'отменено')  THEN
        UPDATE books
        SET available_copies = available_copies + 1
        WHERE book_id = OLD.book_id;
    END IF;

    RETURN NEW;
    END;
$$;
 -   DROP FUNCTION public.add_available_copies();
       public               postgres    false    6            '           1255    74169    calculate_rubles_earned()    FUNCTION     ~  CREATE FUNCTION public.calculate_rubles_earned() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    ren_date TIMESTAMP;
    end_ren_date TIMESTAMP;
    ret_date TIMESTAMP;
    cost_ DECIMAL(10, 2);
    discount_percentage DECIMAL(5, 2);
    discounted_price DECIMAL(10, 2);
    rent_days INT;
    days_expelled INT;
	status varchar(20);
	penalty decimal(10, 2);
	rent_days1 int;
BEGIN

SELECT d.discount_id 
    INTO NEW.discount_id
    FROM discounts d
    JOIN books b ON (b.book_id = NEW.book_id) 
    WHERE (d.author_id = b.author_id or d.publisher_id = b.publisher_id)
       OR (d.genre_id = b.genre_id) and (New.rental_date, New.end_rental_date) OVERLAPS (d.date_from, d.date_to)
	order by d.discount desc
    LIMIT 1;

	status := New.book_status;
	if status != 'активно' and status != 'отменено' then

	penalty := New.penalty_for_book_condition;
    -- Получаем дату возврата
    ret_date := NEW.return_date;

	end_ren_date := New.end_rental_date;
    -- Получаем дату аренды
    ren_date := NEW.rental_date;

    -- Получаем стоимость книги
    SELECT cost_per_day INTO cost_ FROM books WHERE book_id = NEW.book_id;

    -- Рассчитываем количество дней аренды
    rent_days := EXTRACT(DAY FROM (end_ren_date-ren_date));

	rent_days1 :=EXTRACT(DAY FROM (ret_date-ren_date));

    -- Получаем скидку
    IF NEW.discount_id IS NOT NULL THEN 
        SELECT discount INTO discount_percentage FROM discounts WHERE discount_id = NEW.discount_id;
    END IF;

    -- Задаем значение дней, которые не были учтены
    IF ret_date IS NOT NULL THEN
        days_expelled := EXTRACT(DAY FROM (ret_date-ren_date));
    ELSE
        days_expelled := 0;
    END IF;

    IF days_expelled > rent_days THEN 
        days_expelled := days_expelled - rent_days; 
    ELSE
        days_expelled := 0;
    END IF;

    -- Если скидка есть, рассчитываем цену с учетом скидки
    IF discount_percentage IS NOT NULL THEN
		if status ='зарезервировано' then 
			discounted_price := (cost_/2) * rent_days * (1 - (discount_percentage / 100)) ;
		else
        	discounted_price := cost_ * rent_days1 * (1 - (discount_percentage / 100)) ;
		end if;
    ELSE
        discounted_price := cost_ * rent_days1;
    END IF;

    IF days_expelled !=0 and days_expelled is not null THEN
        discounted_price := discounted_price + (cost_ * 2 * days_expelled);
    END IF;

	if penalty is not null then
    NEW.rubles_earned := discounted_price + penalty; -- Пример расчета за количество дней
	else
	NEW.rubles_earned := discounted_price;
	end if;



    RETURN NEW;
else 
New.rubles_earned :=0;
return New;
end if;
END;
$$;
 0   DROP FUNCTION public.calculate_rubles_earned();
       public               postgres    false    6            L           1255    74171    set_discount_id()    FUNCTION       CREATE FUNCTION public.set_discount_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Устанавливаем discount_id на основе совпадения author, publisher или genre из таблицы books
    SELECT d.discount_id 
    INTO NEW.discount_id
    FROM discounts d
    JOIN books b ON (b.book_id = NEW.book_id) 
    WHERE (d.author_id = b.author_id or d.publisher_id = b.publisher_id)
       OR (d.genre_id = b.genre_id)
    LIMIT 1;

    RETURN NEW;
END;
$$;
 (   DROP FUNCTION public.set_discount_id();
       public               postgres    false    6            ;           1255    81922    sub_available_copies()    FUNCTION     �  CREATE FUNCTION public.sub_available_copies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF ((SELECT available_copies FROM books WHERE book_id = NEW.book_id) > 0) and (NEW.book_status = 'активно' or New.book_status = 'зарезервировано') THEN
        -- Вычитаем 1 из количества книг на складе
        UPDATE books
        SET available_copies = available_copies - 1
        WHERE book_id = NEW.book_id;

        RETURN NEW; -- Возвращаем новую запись
    ELSE
        RAISE EXCEPTION 'Книга недоступна для резервирования';
    END IF;
END;
$$;
 -   DROP FUNCTION public.sub_available_copies();
       public               postgres    false    6            �            1255    74464    update_available_copies()    FUNCTION     �  CREATE FUNCTION public.update_available_copies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.book_status = 'активно' or New.book_status = 'зарезервировано' THEN
        UPDATE books
        SET available_copies = GREATEST(0, available_copies - 1)
        WHERE book_id = NEW.book_id; 
    END IF;

    -- Если статус меняется с 'активно' на другой, увеличьте значение
    IF OLD.book_status = 'активно' AND NEW.book_status <> 'активно' THEN
        UPDATE books
        SET available_copies = available_copies + 1
        WHERE book_id = OLD.book_id;
    END IF;

    RETURN NEW;
END;
$$;
 0   DROP FUNCTION public.update_available_copies();
       public               postgres    false    6            �            1255    74466    update_reserved_books_status()    FUNCTION     U  CREATE FUNCTION public.update_reserved_books_status() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE reserved_books
    SET status = 'отменено'
    WHERE status = 'зарезервировано' AND reservation_date < NOW() - INTERVAL '30 days'; -- замените 30 на нужный вам срок
END;
$$;
 5   DROP FUNCTION public.update_reserved_books_status();
       public               postgres    false    6            �            1259    74339    authors    TABLE     b   CREATE TABLE public.authors (
    author_id integer NOT NULL,
    author character varying(40)
);
    DROP TABLE public.authors;
       public         heap r       postgres    false    6            �            1259    74338    authors_author_id_seq    SEQUENCE     �   CREATE SEQUENCE public.authors_author_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.authors_author_id_seq;
       public               postgres    false    220    6            �           0    0    authors_author_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.authors_author_id_seq OWNED BY public.authors.author_id;
          public               postgres    false    219            �            1259    74374    books    TABLE     �  CREATE TABLE public.books (
    book_id integer NOT NULL,
    name character varying(50) NOT NULL,
    author_id integer NOT NULL,
    path_to_book_cover character varying(50) NOT NULL,
    year_of_production date NOT NULL,
    genre_id integer NOT NULL,
    publisher_id integer NOT NULL,
    number_of_pages integer NOT NULL,
    cost_per_day numeric(10,2) NOT NULL,
    available_copies integer DEFAULT 0 NOT NULL,
    isbn character varying(20) NOT NULL,
    description character varying(500)
);
    DROP TABLE public.books;
       public         heap r       postgres    false    6            �            1259    74373    books_book_id_seq    SEQUENCE     �   CREATE SEQUENCE public.books_book_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.books_book_id_seq;
       public               postgres    false    228    6            �           0    0    books_book_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.books_book_id_seq OWNED BY public.books.book_id;
          public               postgres    false    227            �            1259    74399 	   discounts    TABLE     J  CREATE TABLE public.discounts (
    discount_id integer NOT NULL,
    name_of_discount character varying(60) NOT NULL,
    discount numeric(5,2) NOT NULL,
    date_from timestamp without time zone NOT NULL,
    date_to timestamp without time zone NOT NULL,
    author_id integer,
    genre_id integer,
    publisher_id integer
);
    DROP TABLE public.discounts;
       public         heap r       postgres    false    6            �            1259    74398    discounts_discount_id_seq    SEQUENCE     �   CREATE SEQUENCE public.discounts_discount_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.discounts_discount_id_seq;
       public               postgres    false    230    6            �           0    0    discounts_discount_id_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.discounts_discount_id_seq OWNED BY public.discounts.discount_id;
          public               postgres    false    229            �            1259    74346    genres    TABLE     h   CREATE TABLE public.genres (
    genre_id integer NOT NULL,
    genre character varying(40) NOT NULL
);
    DROP TABLE public.genres;
       public         heap r       postgres    false    6            �            1259    74345    genres_genre_id_seq    SEQUENCE     �   CREATE SEQUENCE public.genres_genre_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.genres_genre_id_seq;
       public               postgres    false    6    222            �           0    0    genres_genre_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.genres_genre_id_seq OWNED BY public.genres.genre_id;
          public               postgres    false    221            �            1259    74353 
   publishers    TABLE     t   CREATE TABLE public.publishers (
    publisher_id integer NOT NULL,
    publisher character varying(40) NOT NULL
);
    DROP TABLE public.publishers;
       public         heap r       postgres    false    6            �            1259    74352    publishers_publisher_id_seq    SEQUENCE     �   CREATE SEQUENCE public.publishers_publisher_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.publishers_publisher_id_seq;
       public               postgres    false    224    6            �           0    0    publishers_publisher_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.publishers_publisher_id_seq OWNED BY public.publishers.publisher_id;
          public               postgres    false    223            �            1259    74421    reserved_books    TABLE     �  CREATE TABLE public.reserved_books (
    rent_id integer NOT NULL,
    book_id integer NOT NULL,
    user_id integer NOT NULL,
    book_status character varying(20) NOT NULL,
    rental_date timestamp without time zone NOT NULL,
    end_rental_date timestamp without time zone NOT NULL,
    return_date timestamp without time zone,
    penalty_for_book_condition numeric,
    rubles_earned numeric(10,2) NOT NULL,
    discount_id integer,
    CONSTRAINT reserved_books_book_status_check CHECK (((book_status)::text = ANY ((ARRAY['зарезервировано'::character varying, 'отменено'::character varying, 'активно'::character varying, 'возвращено'::character varying])::text[])))
);
 "   DROP TABLE public.reserved_books;
       public         heap r       postgres    false    6            �            1259    74420    reserved_books_rent_id_seq    SEQUENCE     �   CREATE SEQUENCE public.reserved_books_rent_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.reserved_books_rent_id_seq;
       public               postgres    false    232    6            �           0    0    reserved_books_rent_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.reserved_books_rent_id_seq OWNED BY public.reserved_books.rent_id;
          public               postgres    false    231            �            1259    74360    users    TABLE     �  CREATE TABLE public.users (
    user_id integer NOT NULL,
    username character varying(30) NOT NULL,
    email public.citext NOT NULL,
    password character varying(100) NOT NULL,
    role character varying(20),
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['директор'::character varying, 'читатель'::character varying, 'библиотекарь'::character varying])::text[])))
);
    DROP TABLE public.users;
       public         heap r       postgres    false    6    6    6    6    6    6    6    6    6    6    6            �            1259    74359    users_user_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.users_user_id_seq;
       public               postgres    false    6    226            �           0    0    users_user_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;
          public               postgres    false    225            �            1259    74446    wishlist    TABLE     m   CREATE TABLE public.wishlist (
    wishlist_id integer NOT NULL,
    user_id integer,
    book_id integer
);
    DROP TABLE public.wishlist;
       public         heap r       postgres    false    6            �            1259    74445    wishlist_wishlist_id_seq    SEQUENCE     �   CREATE SEQUENCE public.wishlist_wishlist_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.wishlist_wishlist_id_seq;
       public               postgres    false    6    234            �           0    0    wishlist_wishlist_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.wishlist_wishlist_id_seq OWNED BY public.wishlist.wishlist_id;
          public               postgres    false    233            �           2604    74342    authors author_id    DEFAULT     v   ALTER TABLE ONLY public.authors ALTER COLUMN author_id SET DEFAULT nextval('public.authors_author_id_seq'::regclass);
 @   ALTER TABLE public.authors ALTER COLUMN author_id DROP DEFAULT;
       public               postgres    false    220    219    220            �           2604    74377    books book_id    DEFAULT     n   ALTER TABLE ONLY public.books ALTER COLUMN book_id SET DEFAULT nextval('public.books_book_id_seq'::regclass);
 <   ALTER TABLE public.books ALTER COLUMN book_id DROP DEFAULT;
       public               postgres    false    227    228    228            �           2604    74402    discounts discount_id    DEFAULT     ~   ALTER TABLE ONLY public.discounts ALTER COLUMN discount_id SET DEFAULT nextval('public.discounts_discount_id_seq'::regclass);
 D   ALTER TABLE public.discounts ALTER COLUMN discount_id DROP DEFAULT;
       public               postgres    false    229    230    230            �           2604    74349    genres genre_id    DEFAULT     r   ALTER TABLE ONLY public.genres ALTER COLUMN genre_id SET DEFAULT nextval('public.genres_genre_id_seq'::regclass);
 >   ALTER TABLE public.genres ALTER COLUMN genre_id DROP DEFAULT;
       public               postgres    false    221    222    222            �           2604    74356    publishers publisher_id    DEFAULT     �   ALTER TABLE ONLY public.publishers ALTER COLUMN publisher_id SET DEFAULT nextval('public.publishers_publisher_id_seq'::regclass);
 F   ALTER TABLE public.publishers ALTER COLUMN publisher_id DROP DEFAULT;
       public               postgres    false    224    223    224            �           2604    74424    reserved_books rent_id    DEFAULT     �   ALTER TABLE ONLY public.reserved_books ALTER COLUMN rent_id SET DEFAULT nextval('public.reserved_books_rent_id_seq'::regclass);
 E   ALTER TABLE public.reserved_books ALTER COLUMN rent_id DROP DEFAULT;
       public               postgres    false    232    231    232            �           2604    74363    users user_id    DEFAULT     n   ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);
 <   ALTER TABLE public.users ALTER COLUMN user_id DROP DEFAULT;
       public               postgres    false    225    226    226            �           2604    74449    wishlist wishlist_id    DEFAULT     |   ALTER TABLE ONLY public.wishlist ALTER COLUMN wishlist_id SET DEFAULT nextval('public.wishlist_wishlist_id_seq'::regclass);
 C   ALTER TABLE public.wishlist ALTER COLUMN wishlist_id DROP DEFAULT;
       public               postgres    false    234    233    234            �          0    74339    authors 
   TABLE DATA           4   COPY public.authors (author_id, author) FROM stdin;
    public               postgres    false    220   �}       �          0    74374    books 
   TABLE DATA           �   COPY public.books (book_id, name, author_id, path_to_book_cover, year_of_production, genre_id, publisher_id, number_of_pages, cost_per_day, available_copies, isbn, description) FROM stdin;
    public               postgres    false    228   9~       �          0    74399 	   discounts 
   TABLE DATA           �   COPY public.discounts (discount_id, name_of_discount, discount, date_from, date_to, author_id, genre_id, publisher_id) FROM stdin;
    public               postgres    false    230   �       �          0    74346    genres 
   TABLE DATA           1   COPY public.genres (genre_id, genre) FROM stdin;
    public               postgres    false    222   ��       �          0    74353 
   publishers 
   TABLE DATA           =   COPY public.publishers (publisher_id, publisher) FROM stdin;
    public               postgres    false    224   �       �          0    74421    reserved_books 
   TABLE DATA           �   COPY public.reserved_books (rent_id, book_id, user_id, book_status, rental_date, end_rental_date, return_date, penalty_for_book_condition, rubles_earned, discount_id) FROM stdin;
    public               postgres    false    232   N�       �          0    74360    users 
   TABLE DATA           I   COPY public.users (user_id, username, email, password, role) FROM stdin;
    public               postgres    false    226   �       �          0    74446    wishlist 
   TABLE DATA           A   COPY public.wishlist (wishlist_id, user_id, book_id) FROM stdin;
    public               postgres    false    234   ��       �           0    0    authors_author_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.authors_author_id_seq', 3, true);
          public               postgres    false    219            �           0    0    books_book_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.books_book_id_seq', 3, true);
          public               postgres    false    227            �           0    0    discounts_discount_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.discounts_discount_id_seq', 3, true);
          public               postgres    false    229            �           0    0    genres_genre_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.genres_genre_id_seq', 4, true);
          public               postgres    false    221            �           0    0    publishers_publisher_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.publishers_publisher_id_seq', 3, true);
          public               postgres    false    223            �           0    0    reserved_books_rent_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.reserved_books_rent_id_seq', 9, true);
          public               postgres    false    231            �           0    0    users_user_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.users_user_id_seq', 58, true);
          public               postgres    false    225            �           0    0    wishlist_wishlist_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.wishlist_wishlist_id_seq', 3, true);
          public               postgres    false    233            �           2606    74344    authors authors_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (author_id);
 >   ALTER TABLE ONLY public.authors DROP CONSTRAINT authors_pkey;
       public                 postgres    false    220            �           2606    74382    books books_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (book_id);
 :   ALTER TABLE ONLY public.books DROP CONSTRAINT books_pkey;
       public                 postgres    false    228            �           2606    74404    discounts discounts_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.discounts
    ADD CONSTRAINT discounts_pkey PRIMARY KEY (discount_id);
 B   ALTER TABLE ONLY public.discounts DROP CONSTRAINT discounts_pkey;
       public                 postgres    false    230            �           2606    74351    genres genres_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (genre_id);
 <   ALTER TABLE ONLY public.genres DROP CONSTRAINT genres_pkey;
       public                 postgres    false    222            �           2606    74358    publishers publishers_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT publishers_pkey PRIMARY KEY (publisher_id);
 D   ALTER TABLE ONLY public.publishers DROP CONSTRAINT publishers_pkey;
       public                 postgres    false    224            �           2606    74429 "   reserved_books reserved_books_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.reserved_books
    ADD CONSTRAINT reserved_books_pkey PRIMARY KEY (rent_id);
 L   ALTER TABLE ONLY public.reserved_books DROP CONSTRAINT reserved_books_pkey;
       public                 postgres    false    232            �           2606    74372    users users_email_key 
   CONSTRAINT     Q   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);
 ?   ALTER TABLE ONLY public.users DROP CONSTRAINT users_email_key;
       public                 postgres    false    226            �           2606    74368    users users_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public                 postgres    false    226            �           2606    74370    users users_username_key 
   CONSTRAINT     W   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);
 B   ALTER TABLE ONLY public.users DROP CONSTRAINT users_username_key;
       public                 postgres    false    226            �           2606    74451    wishlist wishlist_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.wishlist
    ADD CONSTRAINT wishlist_pkey PRIMARY KEY (wishlist_id);
 @   ALTER TABLE ONLY public.wishlist DROP CONSTRAINT wishlist_pkey;
       public                 postgres    false    234            �           2620    81927 #   reserved_books reserve_book_trigger    TRIGGER     �   CREATE TRIGGER reserve_book_trigger BEFORE INSERT ON public.reserved_books FOR EACH ROW EXECUTE FUNCTION public.sub_available_copies();
 <   DROP TRIGGER reserve_book_trigger ON public.reserved_books;
       public               postgres    false    232    315            �           2620    81928 $   reserved_books reserve_book_trigger1    TRIGGER     �   CREATE TRIGGER reserve_book_trigger1 BEFORE UPDATE ON public.reserved_books FOR EACH ROW EXECUTE FUNCTION public.add_available_copies();
 =   DROP TRIGGER reserve_book_trigger1 ON public.reserved_books;
       public               postgres    false    322    232            �           2620    81926 *   reserved_books trg_calculate_rubles_earned    TRIGGER     �   CREATE TRIGGER trg_calculate_rubles_earned BEFORE INSERT OR UPDATE ON public.reserved_books FOR EACH ROW EXECUTE FUNCTION public.calculate_rubles_earned();
 C   DROP TRIGGER trg_calculate_rubles_earned ON public.reserved_books;
       public               postgres    false    295    232            �           2606    74383    books books_author_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.authors(author_id);
 D   ALTER TABLE ONLY public.books DROP CONSTRAINT books_author_id_fkey;
       public               postgres    false    220    228    4821            �           2606    74388    books books_genre_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES public.genres(genre_id);
 C   ALTER TABLE ONLY public.books DROP CONSTRAINT books_genre_id_fkey;
       public               postgres    false    228    4823    222            �           2606    74393    books books_publisher_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_publisher_id_fkey FOREIGN KEY (publisher_id) REFERENCES public.publishers(publisher_id);
 G   ALTER TABLE ONLY public.books DROP CONSTRAINT books_publisher_id_fkey;
       public               postgres    false    4825    228    224            �           2606    74405 "   discounts discounts_author_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.discounts
    ADD CONSTRAINT discounts_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.authors(author_id);
 L   ALTER TABLE ONLY public.discounts DROP CONSTRAINT discounts_author_id_fkey;
       public               postgres    false    220    230    4821            �           2606    74410 !   discounts discounts_genre_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.discounts
    ADD CONSTRAINT discounts_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES public.genres(genre_id);
 K   ALTER TABLE ONLY public.discounts DROP CONSTRAINT discounts_genre_id_fkey;
       public               postgres    false    4823    230    222            �           2606    74415 %   discounts discounts_publisher_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.discounts
    ADD CONSTRAINT discounts_publisher_id_fkey FOREIGN KEY (publisher_id) REFERENCES public.publishers(publisher_id);
 O   ALTER TABLE ONLY public.discounts DROP CONSTRAINT discounts_publisher_id_fkey;
       public               postgres    false    224    4825    230            �           2606    74430 *   reserved_books reserved_books_book_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.reserved_books
    ADD CONSTRAINT reserved_books_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(book_id);
 T   ALTER TABLE ONLY public.reserved_books DROP CONSTRAINT reserved_books_book_id_fkey;
       public               postgres    false    228    4833    232            �           2606    74440 .   reserved_books reserved_books_discount_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.reserved_books
    ADD CONSTRAINT reserved_books_discount_id_fkey FOREIGN KEY (discount_id) REFERENCES public.discounts(discount_id);
 X   ALTER TABLE ONLY public.reserved_books DROP CONSTRAINT reserved_books_discount_id_fkey;
       public               postgres    false    230    232    4835            �           2606    74435 *   reserved_books reserved_books_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.reserved_books
    ADD CONSTRAINT reserved_books_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);
 T   ALTER TABLE ONLY public.reserved_books DROP CONSTRAINT reserved_books_user_id_fkey;
       public               postgres    false    4829    226    232            �           2606    74457    wishlist wishlist_book_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.wishlist
    ADD CONSTRAINT wishlist_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(book_id);
 H   ALTER TABLE ONLY public.wishlist DROP CONSTRAINT wishlist_book_id_fkey;
       public               postgres    false    228    4833    234            �           2606    74452    wishlist wishlist_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.wishlist
    ADD CONSTRAINT wishlist_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);
 H   ALTER TABLE ONLY public.wishlist DROP CONSTRAINT wishlist_user_id_fkey;
       public               postgres    false    4829    234    226            �   y   x�=�A
�@�;���w|�&"^<DH.�ѳ���1$o����
g��z��̃E)r%�@������1�zV��ǓAo2�m��j�x�tvp��o���e���ۧ��Y;�ȼ�ʔ�Vf�,�[i      �   �  x�eV�j�V}���0O	X�4����R�s��!�q�dJ�ڧ��8e�6iSB�Pz�PJ5���h$���I����3��q�sٗ��^'��_��teF^��~���<��?�b���q�$���#/��v�0���vz�N�^��u{~�������	�=��_���f�J�JJ�_�J_ꥎu�K31���]`��߉ҿ��+,�J�ՙ9��W���q���f��T'f�s|]�J݋z��f�C��E���fF`�'c]HV���ʌ��\ �-�J�t��5~���vWR*�֘b;�t`�(ǖ�P(5Cm);0#l�$P�'	��B�\i.����A�~�A�	د�eF
p���&�,�cdF��"��PdR�J��P� �W�`dwx~���0��ҜK�m����1R��b�zcs��Cs���.m�L!�)��&&�d$������v&qHAjca��mY���m>���X4q&�fLbg8uA
̹�u�/�ˡLJ����R6��@�K�DGg�e�$�ה�c��V�R���{+	{�U?c&3�kz��P��[��V�)�ג���{YH�.�R��HI�I�:b ������[-��5*c��i��ѓϾ:�qn��Ѝs'ۭ��	9�]7�Q׏�^����)R�y=����8�J�H�I���Tc]MC�Ć}$Yj��}!L�,'���h����"Ŏ�X��4���nF6
D��Z� ��U��P�6˿S�� ſ�W),�:jY<kN��omXI�h�
�2eg_Һ��0J���r[YSJ��ԓ�Y`͉�cd�f��0�BLO�H�7T����(G�L�K��:)�n�jF��f*���ܨTnZ�]��+.���X�J-o&K�ԙ�?'�sƸb��&c�k�nX%Ct`��$!f4 K�}0F�MlN���?:������G��Ϗ���>v��^ө>��V��D�Q�~Ś����v�]O�)qX��� ��q�����Z�έ����VZ��L��#�ۅ�w^��ʗLJ��wej��w߁���?s*��I�oB#�+�{)�,���SSB�H��G�Q������K�P�W��Y�g,��O'c��e\J�ީ<;���J��))MI�|n�N�+�☯��"��?���l�yg���~��_��փ�EG��Ysu3�C}��}h�lmm��3��      �   �   x���M
�0���)�q�2I���=���s+�p#x��CC=�ˍ����c~��|3Z��=G�,-F.���M-φ��j"a�,+�,E����iS���5a9HS�w?�Gv�
g����6�ɑS���[�p�nmh�27�m���:sz&ux ���eb�鄫�n슟YF6���Y�4      �   \   x�3�0��֋M�^�$w\��e�yaɅ��.6�w]��e�yaօ�`�F��	H���>�о�-@r��S�bÅ}������� w?l      �   /   x�$ ��1	Эксмо
2	МИФ
3	АСТ
\.


i>v      �   �   x���Q
�0���S�J�Z;v���Ì��6� ��<C��iN�̇�Д���O�
���x��yPTH�	��b֨�h�5��Dm�����x�Vr+9p/� ٯ�`w���L6�I��eR�A�~|H��W�%�ɕ6�u�gߋ�v6σU؛ֿ5Q�{0����+���/���הZ�	����      �   ~  x�e��N�@��ӧp�z(�����-V~J+4n�?4��BC\U��}
5� �0}#'ML�.ιɽ��[�����Ϭ��`���
4_�CW딯�޲-Z�s�dB�$>[jV�|!s�#�4�al3���4�=�d�����G��9K�,��?��l�� ��&��𥣙���bk����q����͎^6߳ ch&�d��Esќ�:�W�!�?� [��쁐��/r���x�{�����"'J���b��U/G����IU����ݮuz��w�	��u<-A"���'fOTdC�Y�Y�� ���4�"�R��K����'��EE���tVY��u�f��@�q�q�#��$�,�m٥�)rr�����R��L��      �      x�3�4�4�2�F\�@Ҙ+F��� !��     