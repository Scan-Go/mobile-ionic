
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE SCHEMA IF NOT EXISTS "public";

ALTER SCHEMA "public" OWNER TO "pg_database_owner";

CREATE OR REPLACE FUNCTION "public"."get_rooms_with_users"() RETURNS TABLE("id" "uuid", "created_at" timestamp with time zone, "users" "uuid"[], "profiles" "json")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT rooms.*, json_agg(profiles.*) AS profiles 
    FROM rooms
    LEFT JOIN LATERAL unnest(rooms.users) AS user_id ON true
    JOIN profiles ON profiles.id = user_id
    GROUP BY rooms.id;
END;
$$;

ALTER FUNCTION "public"."get_rooms_with_users"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."get_rooms_with_users_profile"() RETURNS TABLE("id" "uuid", "created_at" timestamp with time zone, "users" "uuid"[], "profiles" "json")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT rooms.*, json_agg(profiles.*) AS profiles 
    FROM rooms
    LEFT JOIN LATERAL unnest(rooms.users) AS user_id ON true
    JOIN profiles ON profiles.id = user_id
    GROUP BY rooms.id;
END;
$$;

ALTER FUNCTION "public"."get_rooms_with_users_profile"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."handle_new_fcm_token"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
    -- Check if the entry exists
    IF EXISTS (SELECT 1 FROM public.fcm_tokens WHERE "userId" = new."userId") THEN
        -- If it exists, delete it
        DELETE FROM public.fcm_tokens WHERE "userId" = new."userId";
    END IF;

    return new;

end$$;

ALTER FUNCTION "public"."handle_new_fcm_token"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$begin
  insert into public.profiles (id, "firstName", "lastName")
  values (new.id, new.raw_user_meta_data ->> 'firstName', new.raw_user_meta_data ->> 'lastName');
  return new;
end;
$$;

ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."fcm_tokens" (
    "id" bigint NOT NULL,
    "userId" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "token" "text"
);

ALTER TABLE "public"."fcm_tokens" OWNER TO "postgres";

ALTER TABLE "public"."fcm_tokens" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."fcm_tokens_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."messages" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "fromId" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "toId" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "message" "text" NOT NULL,
    "roomId" "uuid" NOT NULL,
    "read_at" timestamp with time zone,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);

ALTER TABLE "public"."messages" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."notes" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "content" character varying NOT NULL,
    "userId" "uuid" NOT NULL,
    "expire_at" timestamp with time zone NOT NULL,
    "tagId" "uuid"
);

ALTER TABLE "public"."notes" OWNER TO "postgres";

ALTER TABLE "public"."notes" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."notes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."phone_numbers" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "userId" "uuid" NOT NULL,
    "number" character varying NOT NULL
);

ALTER TABLE "public"."phone_numbers" OWNER TO "postgres";

ALTER TABLE "public"."phone_numbers" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."phoneNumbers_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "firstName" character varying NOT NULL,
    "lastName" character varying NOT NULL,
    "profileImageUrl" character varying,
    "sendMessageAllowed" boolean DEFAULT true NOT NULL,
    "showPhoneNumber" boolean DEFAULT false NOT NULL,
    "bio" character varying
);

ALTER TABLE "public"."profiles" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."rooms" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "users" "uuid"[] DEFAULT ARRAY["auth"."uid"()] NOT NULL
);

ALTER TABLE "public"."rooms" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."social_media_accounts" (
    "id" bigint NOT NULL,
    "twitter" character varying,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "userId" "uuid"
);

ALTER TABLE "public"."social_media_accounts" OWNER TO "postgres";

ALTER TABLE "public"."social_media_accounts" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."social_media_accounts_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."tags" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" character varying NOT NULL,
    "note" character varying NOT NULL,
    "userId" "uuid" NOT NULL,
    "isAvailable" boolean DEFAULT true,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);

ALTER TABLE "public"."tags" OWNER TO "postgres";

ALTER TABLE ONLY "public"."fcm_tokens"
    ADD CONSTRAINT "fcm_tokens_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."notes"
    ADD CONSTRAINT "notes_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."phone_numbers"
    ADD CONSTRAINT "phoneNumbers_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."rooms"
    ADD CONSTRAINT "rooms_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."social_media_accounts"
    ADD CONSTRAINT "social_media_accounts_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "tags_pkey" PRIMARY KEY ("id");

CREATE OR REPLACE TRIGGER "delete_old_fcm_token_before_adding_new" BEFORE INSERT ON "public"."fcm_tokens" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_fcm_token"();

ALTER TABLE ONLY "public"."fcm_tokens"
    ADD CONSTRAINT "public_fcm_tokens_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "public_messages_fromId_fkey" FOREIGN KEY ("fromId") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "public_messages_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES "public"."rooms"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "public_messages_toId_fkey" FOREIGN KEY ("toId") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."notes"
    ADD CONSTRAINT "public_notes_tagId_fkey" FOREIGN KEY ("tagId") REFERENCES "public"."tags"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."notes"
    ADD CONSTRAINT "public_notes_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."phone_numbers"
    ADD CONSTRAINT "public_phoneNumbers_userId_fkey" FOREIGN KEY ("userId") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."phone_numbers"
    ADD CONSTRAINT "public_phone_numbers_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "public_profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."social_media_accounts"
    ADD CONSTRAINT "public_social_media_accounts_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "public_tags_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;

CREATE POLICY "Enable delete for users based on user_id" ON "public"."notes" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "userId"));

CREATE POLICY "Enable insert for authenticated users only" ON "public"."notes" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."phone_numbers" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users only" ON "public"."tags" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert for users based on user_id" ON "public"."messages" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "fromId"));

CREATE POLICY "Enable insert for users based on user_id" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable insert only for authenticated user" ON "public"."social_media_accounts" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "userId"));

CREATE POLICY "Enable read access for all users" ON "public"."messages" FOR SELECT TO "authenticated" USING ((("auth"."uid"() = "fromId") OR ("auth"."uid"() = "toId")));

CREATE POLICY "Enable read access for all users" ON "public"."profiles" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."social_media_accounts" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON "public"."tags" FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users, Do not include expired notes." ON "public"."notes" FOR SELECT USING (("expire_at" > CURRENT_TIMESTAMP));

CREATE POLICY "Enable update for users based on their uid" ON "public"."notes" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "userId")) WITH CHECK (("auth"."uid"() = "userId"));

CREATE POLICY "Enable update for users based on uid" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Enable update for users based on uid" ON "public"."social_media_accounts" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "userId")) WITH CHECK (("auth"."uid"() = "userId"));

CREATE POLICY "Enable update for users based on userid" ON "public"."phone_numbers" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "userId")) WITH CHECK (("auth"."uid"() = "userId"));

CREATE POLICY "Enable update for users based on useruid" ON "public"."tags" FOR UPDATE USING (("auth"."uid"() = "userId")) WITH CHECK (("auth"."uid"() = "userId"));

CREATE POLICY "Get user phone number if user allowed it" ON "public"."phone_numbers" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "phone_numbers"."userId") AND ("profiles"."showPhoneNumber" = true)))));

ALTER TABLE "public"."fcm_tokens" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."notes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."phone_numbers" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."social_media_accounts" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."tags" ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."get_rooms_with_users"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_rooms_with_users"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_rooms_with_users"() TO "service_role";

GRANT ALL ON FUNCTION "public"."get_rooms_with_users_profile"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_rooms_with_users_profile"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_rooms_with_users_profile"() TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_new_fcm_token"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_fcm_token"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_fcm_token"() TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";

GRANT ALL ON TABLE "public"."fcm_tokens" TO "anon";
GRANT ALL ON TABLE "public"."fcm_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."fcm_tokens" TO "service_role";

GRANT ALL ON SEQUENCE "public"."fcm_tokens_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."fcm_tokens_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."fcm_tokens_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";

GRANT ALL ON TABLE "public"."notes" TO "anon";
GRANT ALL ON TABLE "public"."notes" TO "authenticated";
GRANT ALL ON TABLE "public"."notes" TO "service_role";

GRANT ALL ON SEQUENCE "public"."notes_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."notes_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."notes_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."phone_numbers" TO "anon";
GRANT ALL ON TABLE "public"."phone_numbers" TO "authenticated";
GRANT ALL ON TABLE "public"."phone_numbers" TO "service_role";

GRANT ALL ON SEQUENCE "public"."phoneNumbers_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."phoneNumbers_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."phoneNumbers_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";

GRANT ALL ON TABLE "public"."rooms" TO "anon";
GRANT ALL ON TABLE "public"."rooms" TO "authenticated";
GRANT ALL ON TABLE "public"."rooms" TO "service_role";

GRANT ALL ON TABLE "public"."social_media_accounts" TO "anon";
GRANT ALL ON TABLE "public"."social_media_accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."social_media_accounts" TO "service_role";

GRANT ALL ON SEQUENCE "public"."social_media_accounts_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."social_media_accounts_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."social_media_accounts_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."tags" TO "anon";
GRANT ALL ON TABLE "public"."tags" TO "authenticated";
GRANT ALL ON TABLE "public"."tags" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
