--
-- PostgreSQL database dump
--

\restrict ywpEtCdrvVjKv4mwtjYV1lxIqYPRJVBSduZcloGOoLDXU0nxAvXDaoPtmlHIGAl

-- Dumped from database version 16.13 (Debian 16.13-1.pgdg13+1)
-- Dumped by pg_dump version 16.13 (Debian 16.13-1.pgdg13+1)

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

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: change_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.change_log (
    log_id integer NOT NULL,
    entity_type text NOT NULL,
    entity_id integer NOT NULL,
    field_name text,
    old_value text,
    new_value text,
    editor text,
    edit_status text,
    reviewer text,
    reviewed boolean DEFAULT false NOT NULL,
    review text,
    changed_at timestamp with time zone DEFAULT now() NOT NULL,
    reviewed_at timestamp with time zone
);


--
-- Name: change_log_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.change_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: change_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.change_log_log_id_seq OWNED BY public.change_log.log_id;


--
-- Name: departure; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departure (
    departure_id integer NOT NULL,
    option_id integer NOT NULL,
    departure_date date NOT NULL,
    start_time time without time zone NOT NULL,
    source text NOT NULL,
    availability_id integer,
    docking_id integer,
    status text DEFAULT 'open'::text NOT NULL,
    manually_closed boolean DEFAULT false NOT NULL,
    closed_by text,
    closed_at timestamp with time zone,
    close_reason text,
    max_pax integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_departure_source CHECK ((((source = 'schedule'::text) AND (availability_id IS NOT NULL) AND (docking_id IS NULL)) OR ((source = 'docking'::text) AND (docking_id IS NOT NULL) AND (availability_id IS NULL)) OR ((source = 'manual'::text) AND (availability_id IS NULL) AND (docking_id IS NULL)))),
    CONSTRAINT chk_manual_close CHECK (((manually_closed = false) OR ((manually_closed = true) AND (closed_by IS NOT NULL) AND (closed_at IS NOT NULL)))),
    CONSTRAINT departure_source_check CHECK ((source = ANY (ARRAY['schedule'::text, 'docking'::text, 'manual'::text]))),
    CONSTRAINT departure_status_check CHECK ((status = ANY (ARRAY['open'::text, 'closed'::text, 'cancelled'::text, 'completed'::text])))
);


--
-- Name: departure_departure_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departure_departure_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: departure_departure_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.departure_departure_id_seq OWNED BY public.departure.departure_id;


--
-- Name: discount; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discount (
    discount_id integer NOT NULL,
    name text NOT NULL,
    platform_id integer,
    shorex_id integer,
    tour_id integer,
    option_id integer,
    discount_pct numeric(6,4) NOT NULL,
    promo_code text,
    valid_from date DEFAULT CURRENT_DATE NOT NULL,
    valid_to date,
    status text DEFAULT 'active'::text NOT NULL,
    created_by text,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_discount_validity CHECK (((valid_to IS NULL) OR (valid_to >= valid_from))),
    CONSTRAINT discount_discount_pct_check CHECK (((discount_pct > (0)::numeric) AND (discount_pct <= (1)::numeric))),
    CONSTRAINT discount_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'expired'::text])))
);


--
-- Name: discount_discount_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discount_discount_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discount_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discount_discount_id_seq OWNED BY public.discount.discount_id;


--
-- Name: note; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.note (
    note_id integer NOT NULL,
    entity_type text NOT NULL,
    entity_id integer NOT NULL,
    note_type text DEFAULT 'general'::text NOT NULL,
    body text NOT NULL,
    author text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT note_note_type_check CHECK ((note_type = ANY (ARRAY['change'::text, 'review'::text, 'general'::text])))
);


--
-- Name: note_note_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.note_note_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: note_note_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.note_note_id_seq OWNED BY public.note.note_id;


--
-- Name: option_availability; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.option_availability (
    availability_id integer NOT NULL,
    option_id integer NOT NULL,
    schedule_type text DEFAULT 'weekly_recurring'::text NOT NULL,
    valid_from date NOT NULL,
    valid_to date,
    mon boolean DEFAULT false NOT NULL,
    tue boolean DEFAULT false NOT NULL,
    wed boolean DEFAULT false NOT NULL,
    thu boolean DEFAULT false NOT NULL,
    fri boolean DEFAULT false NOT NULL,
    sat boolean DEFAULT false NOT NULL,
    sun boolean DEFAULT false NOT NULL,
    cms_status text DEFAULT 'Active'::text NOT NULL,
    CONSTRAINT option_availability_cms_status_check CHECK ((cms_status = ANY (ARRAY['Active'::text, 'Inactive'::text, 'Draft'::text]))),
    CONSTRAINT option_availability_schedule_type_check CHECK ((schedule_type = ANY (ARRAY['weekly_recurring'::text, 'specific_dates'::text])))
);


--
-- Name: option_availability_availability_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_availability_availability_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: option_availability_availability_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_availability_availability_id_seq OWNED BY public.option_availability.availability_id;


--
-- Name: option_blocked_period; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.option_blocked_period (
    blocked_id integer NOT NULL,
    availability_id integer NOT NULL,
    date_from date NOT NULL,
    date_to date NOT NULL,
    reason text,
    CONSTRAINT chk_blocked_range CHECK ((date_to >= date_from))
);


--
-- Name: option_blocked_period_blocked_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_blocked_period_blocked_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: option_blocked_period_blocked_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_blocked_period_blocked_id_seq OWNED BY public.option_blocked_period.blocked_id;


--
-- Name: option_start_time; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.option_start_time (
    start_time_id integer NOT NULL,
    availability_id integer NOT NULL,
    start_time time without time zone NOT NULL
);


--
-- Name: option_start_time_start_time_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.option_start_time_start_time_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: option_start_time_start_time_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.option_start_time_start_time_id_seq OWNED BY public.option_start_time.start_time_id;


--
-- Name: platform; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform (
    platform_id integer NOT NULL,
    name text NOT NULL,
    commission_pct numeric(6,4),
    applies_commission boolean DEFAULT true NOT NULL
);


--
-- Name: platform_commission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_commission (
    commission_id integer NOT NULL,
    platform_id integer NOT NULL,
    shorex_id integer,
    tour_id integer,
    option_id integer,
    commission_pct numeric(6,4) NOT NULL,
    valid_from date DEFAULT CURRENT_DATE NOT NULL,
    valid_to date,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_commission_range CHECK (((commission_pct > (0)::numeric) AND (commission_pct < (1)::numeric))),
    CONSTRAINT chk_commission_validity CHECK (((valid_to IS NULL) OR (valid_to >= valid_from)))
);


--
-- Name: platform_commission_commission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.platform_commission_commission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: platform_commission_commission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.platform_commission_commission_id_seq OWNED BY public.platform_commission.commission_id;


--
-- Name: platform_option; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_option (
    platform_option_id integer NOT NULL,
    platform_tour_id integer NOT NULL,
    external_option_id text,
    name text NOT NULL,
    vex_option_id integer,
    ship_id integer,
    link text
);


--
-- Name: platform_option_platform_option_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.platform_option_platform_option_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: platform_option_platform_option_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.platform_option_platform_option_id_seq OWNED BY public.platform_option.platform_option_id;


--
-- Name: platform_platform_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.platform_platform_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: platform_platform_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.platform_platform_id_seq OWNED BY public.platform.platform_id;


--
-- Name: platform_tour; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_tour (
    platform_tour_id integer NOT NULL,
    platform_id integer NOT NULL,
    external_id text NOT NULL,
    name text NOT NULL,
    link text,
    status text,
    tour_id integer
);


--
-- Name: platform_tour_platform_tour_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.platform_tour_platform_tour_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: platform_tour_platform_tour_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.platform_tour_platform_tour_id_seq OWNED BY public.platform_tour.platform_tour_id;


--
-- Name: port; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.port (
    port_id integer NOT NULL,
    name text NOT NULL
);


--
-- Name: port_port_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.port_port_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: port_port_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.port_port_id_seq OWNED BY public.port.port_id;


--
-- Name: pricing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pricing (
    pricing_id integer NOT NULL,
    shorex_id integer NOT NULL,
    platform_id integer NOT NULL,
    platform_tour_id integer,
    vex_option_id integer,
    price numeric(10,2),
    commission_pct numeric(6,4),
    promo_name text,
    promo_pct numeric(6,4),
    platform_status text,
    link text,
    change_status text,
    editor text,
    reviewer text,
    reviewed boolean DEFAULT false NOT NULL,
    review text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: pricing_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pricing_history (
    history_id integer NOT NULL,
    pricing_id integer NOT NULL,
    shorex_id integer NOT NULL,
    platform_id integer NOT NULL,
    platform_tour_id integer,
    price numeric(10,2),
    commission_pct numeric(6,4),
    platform_status text,
    change_status text,
    editor text,
    reviewer text,
    review text,
    snapshotted_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: pricing_history_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pricing_history_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pricing_history_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pricing_history_history_id_seq OWNED BY public.pricing_history.history_id;


--
-- Name: pricing_pricing_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pricing_pricing_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pricing_pricing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pricing_pricing_id_seq OWNED BY public.pricing.pricing_id;


--
-- Name: schedule_platform_entry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schedule_platform_entry (
    entry_id integer NOT NULL,
    schedule_id integer NOT NULL,
    vex_option_id integer,
    platform_option_id integer,
    expected_price numeric(10,2),
    entry_status text,
    edit_status text,
    editor text,
    reviewer text,
    reviewed boolean DEFAULT false NOT NULL,
    review text,
    CONSTRAINT chk_entry_option CHECK (true)
);


--
-- Name: schedule_platform_entry_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.schedule_platform_entry_entry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schedule_platform_entry_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.schedule_platform_entry_entry_id_seq OWNED BY public.schedule_platform_entry.entry_id;


--
-- Name: ship; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ship (
    ship_id integer NOT NULL,
    name text NOT NULL
);


--
-- Name: ship_docking; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ship_docking (
    docking_id integer NOT NULL,
    ship_id integer NOT NULL,
    port_id integer NOT NULL,
    date date NOT NULL,
    dock_start time without time zone,
    dock_end time without time zone
);


--
-- Name: ship_docking_docking_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ship_docking_docking_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ship_docking_docking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ship_docking_docking_id_seq OWNED BY public.ship_docking.docking_id;


--
-- Name: ship_ship_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ship_ship_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ship_ship_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ship_ship_id_seq OWNED BY public.ship.ship_id;


--
-- Name: shore_excursion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shore_excursion (
    shorex_id integer NOT NULL,
    name text NOT NULL,
    primary_port_id integer
);


--
-- Name: shore_excursion_shorex_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shore_excursion_shorex_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shore_excursion_shorex_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shore_excursion_shorex_id_seq OWNED BY public.shore_excursion.shorex_id;


--
-- Name: tour; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tour (
    tour_id integer NOT NULL,
    shorex_id integer NOT NULL,
    name text NOT NULL,
    status text NOT NULL,
    link text,
    CONSTRAINT tour_status_check CHECK ((status = ANY (ARRAY['Published'::text, 'Draft'::text, 'Excluded'::text])))
);


--
-- Name: tour_option; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tour_option (
    option_id integer NOT NULL,
    tour_id integer NOT NULL,
    name text NOT NULL,
    is_private boolean DEFAULT false NOT NULL,
    ship_id integer,
    base_price numeric(10,2),
    link text
);


--
-- Name: tour_schedule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tour_schedule (
    schedule_id integer NOT NULL,
    docking_id integer NOT NULL,
    shorex_id integer NOT NULL,
    start_time time without time zone,
    tour_type text NOT NULL,
    duration_hours integer,
    status text NOT NULL,
    CONSTRAINT tour_schedule_status_check CHECK ((status = ANY (ARRAY['confirmed'::text, 'Cancelled'::text]))),
    CONSTRAINT tour_schedule_tour_type_check CHECK ((tour_type = ANY (ARRAY['Shared'::text, 'Private'::text])))
);


--
-- Name: tour_schedule_schedule_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tour_schedule_schedule_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tour_schedule_schedule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tour_schedule_schedule_id_seq OWNED BY public.tour_schedule.schedule_id;


--
-- Name: v_active_discounts; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_active_discounts AS
 SELECT d.discount_id,
    d.name,
    d.promo_code,
    COALESCE(pl.name, 'All platforms'::text) AS platform,
    COALESCE(sx.name, 'All excursions'::text) AS shore_excursion,
    COALESCE(t.name, 'All tours'::text) AS tour,
    COALESCE(to2.name, 'All options'::text) AS option,
    ((round((d.discount_pct * (100)::numeric), 2))::text || '%'::text) AS discount_display,
    d.valid_from,
    d.valid_to
   FROM ((((public.discount d
     LEFT JOIN public.platform pl ON ((pl.platform_id = d.platform_id)))
     LEFT JOIN public.shore_excursion sx ON ((sx.shorex_id = d.shorex_id)))
     LEFT JOIN public.tour t ON ((t.tour_id = d.tour_id)))
     LEFT JOIN public.tour_option to2 ON ((to2.option_id = d.option_id)))
  WHERE ((d.status = 'active'::text) AND ((CURRENT_DATE >= d.valid_from) AND (CURRENT_DATE <= COALESCE(d.valid_to, '9999-12-31'::date))))
  ORDER BY d.valid_from;


--
-- Name: v_departure_calendar; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_departure_calendar AS
 SELECT d.departure_id,
    d.departure_date,
    d.start_time,
    sh.name AS ship,
    p.name AS port,
    sx.name AS shore_excursion,
    t.tour_id,
    t.name AS tour_name,
    to2.option_id,
    to2.name AS option_name,
    to2.is_private,
    d.source,
    d.status,
    d.manually_closed,
    d.closed_by,
    d.closed_at,
    d.close_reason,
    d.max_pax
   FROM ((((((public.departure d
     JOIN public.tour_option to2 ON ((to2.option_id = d.option_id)))
     JOIN public.tour t ON ((t.tour_id = to2.tour_id)))
     JOIN public.shore_excursion sx ON ((sx.shorex_id = t.shorex_id)))
     LEFT JOIN public.ship_docking sd ON ((sd.docking_id = d.docking_id)))
     LEFT JOIN public.ship sh ON ((sh.ship_id = sd.ship_id)))
     LEFT JOIN public.port p ON ((p.port_id = sd.port_id)))
  ORDER BY d.departure_date, d.start_time;


--
-- Name: v_effective_commission; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_effective_commission AS
 SELECT po.platform_option_id,
    pt.platform_id,
    pl.name AS platform,
    to2.option_id,
    to2.name AS option_name,
    t.tour_id,
    sx.name AS shore_excursion,
    to2.base_price,
    COALESCE(( SELECT pc.commission_pct
           FROM public.platform_commission pc
          WHERE ((pc.platform_id = pt.platform_id) AND (pc.option_id = to2.option_id) AND ((CURRENT_DATE >= pc.valid_from) AND (CURRENT_DATE <= COALESCE(pc.valid_to, '9999-12-31'::date))))
          ORDER BY pc.valid_from DESC
         LIMIT 1), ( SELECT pc.commission_pct
           FROM public.platform_commission pc
          WHERE ((pc.platform_id = pt.platform_id) AND (pc.tour_id = t.tour_id) AND (pc.option_id IS NULL) AND ((CURRENT_DATE >= pc.valid_from) AND (CURRENT_DATE <= COALESCE(pc.valid_to, '9999-12-31'::date))))
          ORDER BY pc.valid_from DESC
         LIMIT 1), ( SELECT pc.commission_pct
           FROM public.platform_commission pc
          WHERE ((pc.platform_id = pt.platform_id) AND (pc.shorex_id = sx.shorex_id) AND (pc.tour_id IS NULL) AND (pc.option_id IS NULL) AND ((CURRENT_DATE >= pc.valid_from) AND (CURRENT_DATE <= COALESCE(pc.valid_to, '9999-12-31'::date))))
          ORDER BY pc.valid_from DESC
         LIMIT 1), pl.commission_pct) AS effective_commission_pct,
    round((to2.base_price * ((1)::numeric - COALESCE(( SELECT pc.commission_pct
           FROM public.platform_commission pc
          WHERE ((pc.platform_id = pt.platform_id) AND (pc.option_id = to2.option_id) AND ((CURRENT_DATE >= pc.valid_from) AND (CURRENT_DATE <= COALESCE(pc.valid_to, '9999-12-31'::date))))
          ORDER BY pc.valid_from DESC
         LIMIT 1), pl.commission_pct))), 2) AS net_revenue
   FROM (((((public.platform_option po
     JOIN public.platform_tour pt ON ((pt.platform_tour_id = po.platform_tour_id)))
     JOIN public.platform pl ON ((pl.platform_id = pt.platform_id)))
     JOIN public.tour_option to2 ON ((to2.option_id = po.vex_option_id)))
     JOIN public.tour t ON ((t.tour_id = to2.tour_id)))
     JOIN public.shore_excursion sx ON ((sx.shorex_id = t.shorex_id)))
  WHERE (pl.name <> 'Vexperio'::text);


--
-- Name: v_manual_closures; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_manual_closures AS
 SELECT d.departure_id,
    d.departure_date,
    d.start_time,
    sx.name AS shore_excursion,
    to2.name AS option_name,
    to2.is_private,
    sh.name AS ship,
    d.close_reason,
    d.closed_by,
    d.closed_at
   FROM (((((public.departure d
     JOIN public.tour_option to2 ON ((to2.option_id = d.option_id)))
     JOIN public.tour t ON ((t.tour_id = to2.tour_id)))
     JOIN public.shore_excursion sx ON ((sx.shorex_id = t.shorex_id)))
     LEFT JOIN public.ship_docking sd ON ((sd.docking_id = d.docking_id)))
     LEFT JOIN public.ship sh ON ((sh.ship_id = sd.ship_id)))
  WHERE (d.manually_closed = true)
  ORDER BY d.closed_at DESC;


--
-- Name: v_option_availability; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_option_availability AS
 SELECT to2.option_id,
    to2.name AS option_name,
    t.tour_id,
    t.name AS tour_name,
    sx.name AS shore_excursion,
    to2.is_private,
    oa.availability_id,
    oa.valid_from,
    oa.valid_to,
    oa.cms_status,
    TRIM(BOTH ','::text FROM concat_ws(','::text,
        CASE
            WHEN oa.mon THEN 'Mon'::text
            ELSE NULL::text
        END,
        CASE
            WHEN oa.tue THEN 'Tue'::text
            ELSE NULL::text
        END,
        CASE
            WHEN oa.wed THEN 'Wed'::text
            ELSE NULL::text
        END,
        CASE
            WHEN oa.thu THEN 'Thu'::text
            ELSE NULL::text
        END,
        CASE
            WHEN oa.fri THEN 'Fri'::text
            ELSE NULL::text
        END,
        CASE
            WHEN oa.sat THEN 'Sat'::text
            ELSE NULL::text
        END,
        CASE
            WHEN oa.sun THEN 'Sun'::text
            ELSE NULL::text
        END)) AS active_days,
    ( SELECT string_agg((ost.start_time)::text, ', '::text ORDER BY ost.start_time) AS string_agg
           FROM public.option_start_time ost
          WHERE (ost.availability_id = oa.availability_id)) AS start_times,
    ( SELECT count(*) AS count
           FROM public.option_blocked_period obp
          WHERE (obp.availability_id = oa.availability_id)) AS blocked_periods_count
   FROM (((public.option_availability oa
     JOIN public.tour_option to2 ON ((to2.option_id = oa.option_id)))
     JOIN public.tour t ON ((t.tour_id = to2.tour_id)))
     JOIN public.shore_excursion sx ON ((sx.shorex_id = t.shorex_id)))
  ORDER BY sx.name, to2.option_id;


--
-- Name: v_pricing_overview; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_pricing_overview AS
 SELECT sx.name AS shore_excursion,
    pl.name AS platform,
    COALESCE(pt.external_id, ''::text) AS platform_id,
    pt.name AS platform_tour_name,
    pr.price,
    pr.commission_pct,
    round((pr.price * ((1)::numeric - pr.commission_pct)), 2) AS net_revenue,
    pr.platform_status,
    pr.change_status,
    pr.review,
    pr.reviewed,
    pr.editor,
    pr.reviewer
   FROM (((public.pricing pr
     JOIN public.shore_excursion sx ON ((sx.shorex_id = pr.shorex_id)))
     JOIN public.platform pl ON ((pl.platform_id = pr.platform_id)))
     LEFT JOIN public.platform_tour pt ON ((pt.platform_tour_id = pr.platform_tour_id)))
  ORDER BY sx.name, pl.name;


--
-- Name: v_schedule_full; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_schedule_full AS
 SELECT sd.date,
    sh.name AS ship,
    p.name AS port,
    sd.dock_start,
    sd.dock_end,
    sx.name AS shore_excursion,
    ts.start_time,
    ts.tour_type,
    ts.duration_hours,
    ts.status AS schedule_status,
    COALESCE(pl.name, 'Vexperio'::text) AS platform,
    spe.expected_price,
    spe.edit_status,
    spe.editor,
    spe.reviewer,
    spe.reviewed,
    spe.review
   FROM ((((((((public.tour_schedule ts
     JOIN public.ship_docking sd ON ((sd.docking_id = ts.docking_id)))
     JOIN public.ship sh ON ((sh.ship_id = sd.ship_id)))
     JOIN public.port p ON ((p.port_id = sd.port_id)))
     JOIN public.shore_excursion sx ON ((sx.shorex_id = ts.shorex_id)))
     LEFT JOIN public.schedule_platform_entry spe ON ((spe.schedule_id = ts.schedule_id)))
     LEFT JOIN public.platform_option po ON ((po.platform_option_id = spe.platform_option_id)))
     LEFT JOIN public.platform_tour pt ON ((pt.platform_tour_id = po.platform_tour_id)))
     LEFT JOIN public.platform pl ON ((pl.platform_id = pt.platform_id)))
  ORDER BY sd.date, sh.name, ts.start_time;


--
-- Name: change_log log_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.change_log ALTER COLUMN log_id SET DEFAULT nextval('public.change_log_log_id_seq'::regclass);


--
-- Name: departure departure_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departure ALTER COLUMN departure_id SET DEFAULT nextval('public.departure_departure_id_seq'::regclass);


--
-- Name: discount discount_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount ALTER COLUMN discount_id SET DEFAULT nextval('public.discount_discount_id_seq'::regclass);


--
-- Name: note note_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note ALTER COLUMN note_id SET DEFAULT nextval('public.note_note_id_seq'::regclass);


--
-- Name: option_availability availability_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_availability ALTER COLUMN availability_id SET DEFAULT nextval('public.option_availability_availability_id_seq'::regclass);


--
-- Name: option_blocked_period blocked_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_blocked_period ALTER COLUMN blocked_id SET DEFAULT nextval('public.option_blocked_period_blocked_id_seq'::regclass);


--
-- Name: option_start_time start_time_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_start_time ALTER COLUMN start_time_id SET DEFAULT nextval('public.option_start_time_start_time_id_seq'::regclass);


--
-- Name: platform platform_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform ALTER COLUMN platform_id SET DEFAULT nextval('public.platform_platform_id_seq'::regclass);


--
-- Name: platform_commission commission_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_commission ALTER COLUMN commission_id SET DEFAULT nextval('public.platform_commission_commission_id_seq'::regclass);


--
-- Name: platform_option platform_option_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_option ALTER COLUMN platform_option_id SET DEFAULT nextval('public.platform_option_platform_option_id_seq'::regclass);


--
-- Name: platform_tour platform_tour_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_tour ALTER COLUMN platform_tour_id SET DEFAULT nextval('public.platform_tour_platform_tour_id_seq'::regclass);


--
-- Name: port port_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.port ALTER COLUMN port_id SET DEFAULT nextval('public.port_port_id_seq'::regclass);


--
-- Name: pricing pricing_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricing ALTER COLUMN pricing_id SET DEFAULT nextval('public.pricing_pricing_id_seq'::regclass);


--
-- Name: pricing_history history_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricing_history ALTER COLUMN history_id SET DEFAULT nextval('public.pricing_history_history_id_seq'::regclass);


--
-- Name: schedule_platform_entry entry_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_platform_entry ALTER COLUMN entry_id SET DEFAULT nextval('public.schedule_platform_entry_entry_id_seq'::regclass);


--
-- Name: ship ship_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ship ALTER COLUMN ship_id SET DEFAULT nextval('public.ship_ship_id_seq'::regclass);


--
-- Name: ship_docking docking_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ship_docking ALTER COLUMN docking_id SET DEFAULT nextval('public.ship_docking_docking_id_seq'::regclass);


--
-- Name: shore_excursion shorex_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shore_excursion ALTER COLUMN shorex_id SET DEFAULT nextval('public.shore_excursion_shorex_id_seq'::regclass);


--
-- Name: tour_schedule schedule_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tour_schedule ALTER COLUMN schedule_id SET DEFAULT nextval('public.tour_schedule_schedule_id_seq'::regclass);


--
-- Data for Name: change_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.change_log (log_id, entity_type, entity_id, field_name, old_value, new_value, editor, edit_status, reviewer, reviewed, review, changed_at, reviewed_at) FROM stdin;
\.


--
-- Data for Name: departure; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.departure (departure_id, option_id, departure_date, start_time, source, availability_id, docking_id, status, manually_closed, closed_by, closed_at, close_reason, max_pax, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: discount; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.discount (discount_id, name, platform_id, shorex_id, tour_id, option_id, discount_pct, promo_code, valid_from, valid_to, status, created_by, notes, created_at) FROM stdin;
\.


--
-- Data for Name: note; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.note (note_id, entity_type, entity_id, note_type, body, author, created_at) FROM stdin;
1	schedule_platform_entry	8	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Oceana Marina vex id 4691 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
2	schedule_platform_entry	14	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Norwegian Sky vex id 4550 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
3	schedule_platform_entry	19	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Majestic Princess vex id 4549 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
4	schedule_platform_entry	25	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville - Sapphire Princess vex id 4689 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
5	schedule_platform_entry	26	review	Rescheduled to 2 May	Tino	2026-05-13 08:07:21.520551+00
6	schedule_platform_entry	32	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Norwegian Sky vex id 4550 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
7	schedule_platform_entry	37	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Norwegian Star vex id 4696 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
8	schedule_platform_entry	43	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Majestic Princess vex id 4549 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
9	schedule_platform_entry	49	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Norwegian Sky vex id 4550 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
10	schedule_platform_entry	54	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Majestic Princess vex id 4549 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
11	schedule_platform_entry	59	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Oceana Marina vex id 4691 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
12	schedule_platform_entry	66	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Liberty of the Seas vex id 4692 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
13	schedule_platform_entry	71	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Oceana Marina vex id 4691 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
14	schedule_platform_entry	80	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Liberty of the Seas vex id 4692 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
15	schedule_platform_entry	85	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Majestic Princess vex id 4549 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
16	schedule_platform_entry	91	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Norwegian Sky vex id 4550 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
17	schedule_platform_entry	96	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Carnival Legend vex id 4693 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
18	schedule_platform_entry	101	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Crown Princess vex id 4694 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
19	schedule_platform_entry	108	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Oceana Sirena vex id 4695 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
20	schedule_platform_entry	116	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Oceana Marina vex id 4691 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
21	schedule_platform_entry	125	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Carnival Legend vex id 4693 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
22	schedule_platform_entry	130	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Majestic Princess vex id 4549 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
23	schedule_platform_entry	136	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Norwegian Sky vex id 4550 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
24	schedule_platform_entry	141	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Celebrity Apex vex id 4697 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
25	schedule_platform_entry	146	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from  Honfleur and Deauville from Le Havre- Oceania Vista vex id 4552 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
101	pricing	4	change	Platforms (Viator, GYG, PE) - regular price 169,00 eur (this a new price Joanna has asked to add as I have explained yesterday) Vex: 169-10% -> 152,00	\N	2026-05-13 08:07:25.826706+00
26	schedule_platform_entry	155	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Carnival Legend vex id 4693 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
27	schedule_platform_entry	160	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Majestic Princess vex id 4549 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
28	schedule_platform_entry	167	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Liberty of the Seas vex id 4692 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
29	schedule_platform_entry	173	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Norwegian Sky vex id 4550 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
30	schedule_platform_entry	178	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Norwegian Sky vex id 4550 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
31	schedule_platform_entry	183	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Majestic Princess vex id 4549 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
32	schedule_platform_entry	189	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Celebrity Eclipse vex id 4551 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
33	schedule_platform_entry	194	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Oceana Marina vex id 4691 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
34	schedule_platform_entry	199	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Carnival Legend vex id 4693 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
35	schedule_platform_entry	205	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Majestic Princess vex id 4549 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
36	schedule_platform_entry	212	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Majestic Princess vex id 4549 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
37	schedule_platform_entry	218	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Liberty of the Seas vex id 4692 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
38	schedule_platform_entry	224	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Oceania Insignia vex id 4700 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
39	schedule_platform_entry	229	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Liberty of the Seas vex id 4692 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
40	schedule_platform_entry	234	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Sky Princess vex id 4699 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
41	schedule_platform_entry	239	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Norwegian Star vex id 4696 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
42	schedule_platform_entry	245	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre- Liberty of the Seas vex id 4692 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
43	schedule_platform_entry	253	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Liberty of the Seas - 10 hour tour vex id 4604 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
44	schedule_platform_entry	258	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Norwegian Sun - 10 hour tour vex id 4528 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
45	schedule_platform_entry	259	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Liberty of the Seas vex id 4604 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
46	schedule_platform_entry	263	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Sky Princess - 10 hour tour vex id 4605 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
47	schedule_platform_entry	264	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Norwegian Sun vex id 4528 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
48	schedule_platform_entry	266	review	The intended price is 129 currently we've 122	Tino	2026-05-13 08:07:21.520551+00
49	schedule_platform_entry	268	review	The intended price is 179 currently we've 161	Tino	2026-05-13 08:07:21.520551+00
50	schedule_platform_entry	269	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Sky Princess vex id 4605 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
51	schedule_platform_entry	274	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Norwegian Star vex id 4601 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
52	schedule_platform_entry	279	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - MS Nieuw Statendam vex id 1865 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
53	schedule_platform_entry	285	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - MS Nieuw Statendam vex id 1865 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
54	schedule_platform_entry	290	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Carnival Legend vex id 4606 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:07:21.520551+00
55	schedule_platform_entry	293	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
56	schedule_platform_entry	297	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
57	schedule_platform_entry	304	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
58	schedule_platform_entry	307	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
59	schedule_platform_entry	309	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
60	schedule_platform_entry	322	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
61	schedule_platform_entry	331	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
62	schedule_platform_entry	333	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
63	schedule_platform_entry	339	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
64	schedule_platform_entry	342	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
65	schedule_platform_entry	344	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
66	schedule_platform_entry	345	review	Filip cleaned up the other options from Viator and added the day - event link	Tino	2026-05-13 08:07:21.520551+00
67	schedule_platform_entry	349	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
68	schedule_platform_entry	360	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
69	schedule_platform_entry	374	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
70	schedule_platform_entry	376	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
71	schedule_platform_entry	382	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
72	schedule_platform_entry	383	review	Filip cleaned up the other options from Viator and added the day - event link	Tino	2026-05-13 08:07:21.520551+00
73	schedule_platform_entry	409	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
74	schedule_platform_entry	420	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
75	schedule_platform_entry	422	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
76	schedule_platform_entry	428	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
77	schedule_platform_entry	434	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
78	schedule_platform_entry	446	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
79	schedule_platform_entry	448	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
80	schedule_platform_entry	459	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
81	schedule_platform_entry	464	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
82	schedule_platform_entry	467	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
83	schedule_platform_entry	469	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
84	schedule_platform_entry	479	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
85	schedule_platform_entry	489	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
86	schedule_platform_entry	491	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:07:21.520551+00
87	schedule_platform_entry	496	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
88	schedule_platform_entry	531	review	NO availability for October 3 - 23/04	Tino	2026-05-13 08:07:21.520551+00
89	schedule_platform_entry	562	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
90	schedule_platform_entry	568	review	Removed redundant options 21/04	\N	2026-05-13 08:07:21.520551+00
91	schedule_platform_entry	599	review	Resheduled to 2 May	Tino	2026-05-13 08:07:21.520551+00
92	schedule_platform_entry	600	review	redundant option (8-Hour Guided Shore Excursion in Bordeaux 4411) - 21/04	Tino	2026-05-13 08:07:21.520551+00
93	schedule_platform_entry	676	review	redundant option (8-Hour Guided Shore Excursion in Bordeaux 4411) - 21/04	Tino	2026-05-13 08:07:21.520551+00
94	schedule_platform_entry	720	review	redundant option (8-Hour Guided Shore Excursion in Bordeaux 4411) - 21/04	Tino	2026-05-13 08:07:21.520551+00
95	schedule_platform_entry	721	review	redundant option (8-Hour Guided Shore Excursion in Bordeaux 4411) - 21/04	Tino	2026-05-13 08:07:21.520551+00
96	schedule_platform_entry	791	review	redundant option (8-Hour Guided Shore Excursion in Bordeaux 4411) - 21/04	Tino	2026-05-13 08:07:21.520551+00
97	schedule_platform_entry	818	review	redundant option (8-Hour Guided Shore Excursion in Bordeaux 4411) - 21/04	Tino	2026-05-13 08:07:21.520551+00
98	pricing	1	change	Platforms (Viator, GYG, PE) - regular price 169,00 eur (this a new price Joanna has asked to add as I have explained yesterday) Vex: 169-10% -> 152,00	Tino	2026-05-13 08:07:25.826706+00
99	pricing	2	change	Platforms (Viator, GYG, PE) - regular price 169,00 eur (this a new price Joanna has asked to add as I have explained yesterday) Vex: 169-10% -> 152,00	Tino	2026-05-13 08:07:25.826706+00
100	pricing	3	change	Platforms (Viator, GYG, PE) - regular price 169,00 eur (this a new price Joanna has asked to add as I have explained yesterday) Vex: 169-10% -> 152,00	\N	2026-05-13 08:07:25.826706+00
102	pricing	5	change	POYO:\nPlatforms (Viator, GYG, PE) - regular price 129,00\n16 April, 8 July (all visible options should be set with 199,00)(both options 9h and 10h tour)\nVexperio: -10% meaning if we have on other platforms price set for 179,00 then Vexperio ~161; platforms: 199,00 then Vexperio ~179	\N	2026-05-13 08:07:25.826706+00
103	pricing	6	change	POYO:\nPlatforms (Viator, GYG, PE) - regular price 129,00\n16 April, 8 July (all visible options should be set with 199,00)(both options 9h and 10h tour)\nVexperio: -10% meaning if we have on other platforms price set for 179,00 then Vexperio ~161; platforms: 199,00 then Vexperio ~179	\N	2026-05-13 08:07:25.826706+00
104	pricing	7	change	POYO:\nPlatforms (Viator, GYG, PE) - regular price 129,00\n16 April, 8 July (all visible options should be set with 199,00)(both options 9h and 10h tour)\nVexperio: -10% meaning if we have on other platforms price set for 179,00 then Vexperio ~161; platforms: 199,00 then Vexperio ~179	\N	2026-05-13 08:07:25.826706+00
105	pricing	8	change	POYO:\nPlatforms (Viator, GYG, PE) - regular price 129,00\n16 April, 8 July (all visible options should be set with 199,00)(both options 9h and 10h tour)\nVexperio: -10% meaning if we have on other platforms price set for 179,00 then Vexperio ~161; platforms: 199,00 then Vexperio ~179	\N	2026-05-13 08:07:25.826706+00
106	pricing	9	change	Platforms (Viator, GYG, PE) - regular price 179,00 eur\nException:\nall Majestic ships 199,00 (both options 9h and 10h tour) all tours all dates 16 April, 8 July (all visible options should be set with 199,00)\nVexperio: -10% meaning :\nif we have on other platforms price set for 179,00 then Vexperio ~161; platforms: 199,00 then Vexperio ~179	\N	2026-05-13 08:07:25.826706+00
107	pricing	10	change	Platforms (Viator, GYG, PE) - regular price 179,00 eur\nException:\nall Majestic ships 199,00 (both options 9h and 10h tour) all tours all dates 16 April, 8 July (all visible options should be set with 199,00)\nVexperio: -10% meaning :\nif we have on other platforms price set for 179,00 then Vexperio ~161; platforms: 199,00 then Vexperio ~179	\N	2026-05-13 08:07:25.826706+00
108	pricing	11	change	Platforms (Viator, GYG, PE) - regular price 179,00 eur\nException:\nall Majestic ships 199,00 (both options 9h and 10h tour) all tours all dates 16 April, 8 July (all visible options should be set with 199,00)\nVexperio: -10% meaning :\nif we have on other platforms price set for 179,00 then Vexperio ~161; platforms: 199,00 then Vexperio ~179	\N	2026-05-13 08:07:25.826706+00
109	pricing	12	change	Platforms (Viator, GYG, PE) - regular price 179,00 eur\nException:\nall Majestic ships 199,00 (both options 9h and 10h tour) all tours all dates 16 April, 8 July (all visible options should be set with 199,00)\nVexperio: -10% meaning :\nif we have on other platforms price set for 179,00 then Vexperio ~161; platforms: 199,00 then Vexperio ~179	\N	2026-05-13 08:07:25.826706+00
110	pricing	13	change	Port: Cherbourg\nD-day \nPlatforms (Viator, GYG, PE) - regular price 149,00\nVex: 149-10% -> 134,00	\N	2026-05-13 08:07:25.826706+00
111	pricing	14	change	Port: Cherbourg\nD-day \nPlatforms (Viator, GYG, PE) - regular price 149,00\nVex: 149-10% -> 134,00	\N	2026-05-13 08:07:25.826706+00
112	pricing	15	change	Port: Cherbourg\nD-day \nPlatforms (Viator, GYG, PE) - regular price 149,00\nVex: 149-10% -> 134,00	\N	2026-05-13 08:07:25.826706+00
113	pricing	16	change	Port: Cherbourg\nD-day \nPlatforms (Viator, GYG, PE) - regular price 149,00\nVex: 149-10% -> 134,00	\N	2026-05-13 08:07:25.826706+00
114	pricing	17	change	H&D:\nPlatforms (Viator, GYG, PE) - regular price 129,00\nVex: 129-10% -> 116,00	\N	2026-05-13 08:07:25.826706+00
115	pricing	18	change	H&D:\nPlatforms (Viator, GYG, PE) - regular price 129,00\nVex: 129-10% -> 116,00	\N	2026-05-13 08:07:25.826706+00
116	pricing	19	change	H&D:\nPlatforms (Viator, GYG, PE) - regular price 129,00\nVex: 129-10% -> 116,00	\N	2026-05-13 08:07:25.826706+00
117	pricing	20	change	H&D:\nPlatforms (Viator, GYG, PE) - regular price 129,00\nVex: 129-10% -> 116,00	\N	2026-05-13 08:07:25.826706+00
118	pricing	21	change	MSM:\nPlatforms (Viator, GYG, PE) - regular price 159,00\nVex: 159-10% -> 143,00	\N	2026-05-13 08:07:25.826706+00
119	pricing	22	change	MSM:\nPlatforms (Viator, GYG, PE) - regular price 159,00\nVex: 159-10% -> 143,00	\N	2026-05-13 08:07:25.826706+00
120	pricing	23	change	MSM:\nPlatforms (Viator, GYG, PE) - regular price 159,00\nVex: 159-10% -> 143,00	\N	2026-05-13 08:07:25.826706+00
121	pricing	24	change	MSM:\nPlatforms (Viator, GYG, PE) - regular price 159,00\nVex: 159-10% -> 143,00	\N	2026-05-13 08:07:25.826706+00
122	pricing	25	change	Port: LVDBordo Shared tour\nPlatforms (Viator, GYG, PE) - regular price 149,00\nVex: 149-10% -> 134,00	\N	2026-05-13 08:07:25.826706+00
123	pricing	26	change	Port: LVDBordo Shared tour\nPlatforms (Viator, GYG, PE) - regular price 149,00\nVex: 149-10% -> 134,00	\N	2026-05-13 08:07:25.826706+00
124	pricing	27	change	Port: LVDBordo Shared tour\nPlatforms (Viator, GYG, PE) - regular price 149,00\nVex: 149-10% -> 134,00	\N	2026-05-13 08:07:25.826706+00
125	pricing	28	change	Port: LVDBordo Shared tour\nPlatforms (Viator, GYG, PE) - regular price 149,00\nVex: 149-10% -> 134,00	\N	2026-05-13 08:07:25.826706+00
126	pricing	29	change	Bordoyo\nPlatforms (Viator, GYG, PE) - regular price 119,00\nVex: 119-10% -> 107,00	\N	2026-05-13 08:07:25.826706+00
127	pricing	30	change	Bordoyo\nPlatforms (Viator, GYG, PE) - regular price 119,00\nVex: 119-10% -> 107,00	\N	2026-05-13 08:07:25.826706+00
128	pricing	31	change	Bordoyo\nPlatforms (Viator, GYG, PE) - regular price 119,00\nVex: 119-10% -> 107,00	\N	2026-05-13 08:07:25.826706+00
129	pricing	32	change	Bordoyo\nPlatforms (Viator, GYG, PE) - regular price 119,00\nVex: 119-10% -> 107,00	\N	2026-05-13 08:07:25.826706+00
130	pricing	33	change	Platforms (Viator, GYG, PE) - regular price 139,00\nVex: 139-10% -> 125,00	\N	2026-05-13 08:07:25.826706+00
131	pricing	34	change	Platforms (Viator, GYG, PE) - regular price 139,00\nVex: 139-10% -> 125,00	\N	2026-05-13 08:07:25.826706+00
132	pricing	35	change	Platforms (Viator, GYG, PE) - regular price 139,00\nVex: 139-10% -> 125,00	\N	2026-05-13 08:07:25.826706+00
133	schedule_platform_entry	96	review	Tino - Removed Redundant options, and I have the schedule displayed as a combined tour - change date 21 April changed from Honfleur and Deauville from Le Havre - Carnival Legend vex id 4606 to Honfleur and Deauville Shared Tour Ticket 3251	Tino	2026-05-13 08:53:32.715045+00
134	schedule_platform_entry	864	review	Removed redundant options 21/04	\N	2026-05-13 08:53:34.499703+00
135	schedule_platform_entry	14	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:53:34.499703+00
136	schedule_platform_entry	19	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:53:34.499703+00
137	schedule_platform_entry	49	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:53:34.499703+00
138	schedule_platform_entry	54	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:53:34.499703+00
139	schedule_platform_entry	85	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:53:34.499703+00
140	schedule_platform_entry	91	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:53:34.499703+00
141	schedule_platform_entry	130	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:53:34.499703+00
142	schedule_platform_entry	136	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:53:34.499703+00
143	schedule_platform_entry	160	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:53:34.499703+00
144	schedule_platform_entry	173	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:53:34.499703+00
145	schedule_platform_entry	178	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:53:34.499703+00
146	schedule_platform_entry	183	review	Tino -  Removed Redundant options, and I have the schedule displayed as a combined tour -  change date 21/04	Tino	2026-05-13 08:53:34.499703+00
147	schedule_platform_entry	395	review	redundant option (8-Hour Guided Shore Excursion in Bordeaux 4411) - 21/04	Tino	2026-05-13 08:53:36.338352+00
148	schedule_platform_entry	219	review	redundant option (8-Hour Guided Shore Excursion in Bordeaux 4411) - 21/04	Tino	2026-05-13 08:53:36.338352+00
\.


--
-- Data for Name: option_availability; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.option_availability (availability_id, option_id, schedule_type, valid_from, valid_to, mon, tue, wed, thu, fri, sat, sun, cms_status) FROM stdin;
\.


--
-- Data for Name: option_blocked_period; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.option_blocked_period (blocked_id, availability_id, date_from, date_to, reason) FROM stdin;
\.


--
-- Data for Name: option_start_time; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.option_start_time (start_time_id, availability_id, start_time) FROM stdin;
\.


--
-- Data for Name: platform; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.platform (platform_id, name, commission_pct, applies_commission) FROM stdin;
1	Vexperio	\N	f
2	GetYourGuide	0.3710	t
3	Viator	0.2460	t
4	Project Expedition	0.1000	t
\.


--
-- Data for Name: platform_commission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.platform_commission (commission_id, platform_id, shorex_id, tour_id, option_id, commission_pct, valid_from, valid_to, notes, created_at) FROM stdin;
\.


--
-- Data for Name: platform_option; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.platform_option (platform_option_id, platform_tour_id, external_option_id, name, vex_option_id, ship_id, link) FROM stdin;
1	1	1867598	Ticket For Carnival Legend Passengers	4628	3	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
2	1	1867610	Ticket For Oceana Sirena Passengers	4622	5	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
3	1	1867612	Ticket For Celebrity Apex Passengers	4623	4	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
4	1	1867622	Ticket For Sky Princess Passengers	4630	1	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
5	1	1867648	Ticket for Shared ShorEX Tour	4634	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
6	1	1598058	Ticket For Celebrity Eclipse Passengers	4485	13	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
7	1	1867516	Ticket for Sapphire Princess Passengers	4617	10	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
8	1	1598017	Ticket For Norwegian Sky Passengers	4532	12	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
9	1	1598057	Ticket For Norwegian Sun Passengers	4620	7	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
10	1	1598065	Ticket For Nieuw Statendam Passengers	4482	14	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
11	1	1642685	Ticket For Carnival Legend Passengers 9h tour	4509	3	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
12	1	1598054	Ticket For Oceania Vista Passengers	4486	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
13	1	1598060	Ticket for Majestic Princess Passengers	4533	11	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
14	1	1867585	Ticket For Norwegian Star Passengers	4618	9	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
15	1	1867595	Ticket For Liberty of the Seas Passengers	4619	8	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
16	1	1598068	Private Driver and Guide in Paris with Shared Port Transfers	3401	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
17	1	1867603	Ticket For Crown Princess Passengers	4621	6	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
18	1	1867615	Ticket For Oceania Insignia Passengers	4629	2	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024
19	2	1598112	Ticket For Celebrity Eclipse Passengers	4485	13	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
20	2	1598116	Ticket For Nieuw Statendam Passengers	4482	14	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
21	2	1684566	Ticket For Norwegian Sky Passengers	4532	12	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
22	2	1684568	Ticket For Majestic Princess Passengers	4533	11	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
23	2	817859	Private Paris Guided Day Shore Excursion & Shared Transfer	3401	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
24	2	1598100	Ticket For Oceania Vista Passengers	4486	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
25	2	1867700	Ticket For Carnival Legend Passengers	4628	3	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
26	2	794053	Shared Tour Ticket	4491	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
27	2	1684565	Ticket For Carnival Legend Passengers 9h tour	4509	3	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
28	2	1867691	Ticket For Sapphire Princess Passengers	4617	10	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
29	2	1867695	Ticket For Norwegian Star Passengers	4618	9	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
30	2	1867704	Ticket For Liberty of the Seas Passengers	4619	8	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
31	2	1867710	Ticket For Crown Princess Passengers	4621	6	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
32	2	1867711	Ticket For Oceana Sirena Passengers	4622	5	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
33	2	1867716	Ticket For Celebrity Apex Passengers	4623	4	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
34	2	1867719	Ticket For Oceania Insignia Passengers	4629	2	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
35	2	1598113	Ticket For Norwegian Sun Passengers	4620	7	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
36	2	1867725	Ticket For Sky Princess Passengers	4630	1	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
37	2	1867726	Ticket for Shared ShorEX Tour	4634	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548
38	3	1222667	Shared Tour Paris on Your Own	4470	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=477029
39	3	1621197	2026 April 16th Paris - Nieuw Statendam	4479	14	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=477029
40	3	1636863	2026 July 8th Paris - Norwegian Sky	4531	12	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=477029
41	3	1621218	2026 June 2nd Paris - Majestic Princess	4478	11	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=477029
42	3	1621224	2026 August 28th Paris - Celebrity Eclipse	4476	13	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=477029
43	3	1636853	2026 July 18th Paris - Carnival Legend	4510	3	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=477029
44	3	1636859	2026 July 8th Paris - Majestic Princess	4530	11	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=477029
45	3	1370741	Ticket for Paris on Your Own	4469	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=477029
46	3	1621205	2026 April 16th Paris - Majestic Princess	4480	11	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=477029
47	3	1621229	2026 August 28th Paris - Oceania Vista	4475	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=477029
48	4	1830996	D-Day Landing Beaches - Carnival Legend - 9h tour	4614	3	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
49	4	1831005	D-Day Landing Beaches - Oceana Marina - 8h tour	4603	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
50	4	1831103	D-Day Landing Beaches - Liberty of the Seas	4604	8	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
51	4	1831114	D-Day Landing Beaches - Carnival Legend	4606	3	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
52	4	1831154	D-Day Landing Beaches - Crown Princess	4607	6	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
53	4	1831156	D-Day Landing Beaches - Oceana Sirena	4609	5	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
54	4	1831158	D-Day Landing Beaches - Celebrity Apex	4610	4	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
55	4	1831161	D-Day Landing Beaches - Oceania Insignia	4608	2	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
56	4	1831165	D-Day Landing Beaches - Sky Princess	4605	1	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
57	4	1220156	9-Hour D-Day Shared Tour	4493	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
58	4	1299232	Shared Tour Ticket	4495	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
59	4	1880210	Majestic Princess -9h Tour	4642	11	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
60	4	1915670	D-Day Landing Beaches - Norwegian Sky - 9h tour	4657	12	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
61	4	914773	Private Tour	1865	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
62	4	1679414	D-Day Landing Beaches - Celebrity Eclipse	4562	13	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
63	4	1679419	D-Day Landing Beaches - Oceania Vista	4563	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
64	4	1820186	D-Day Landing Beaches - Sapphire Princess	4602	10	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
65	4	1820195	D-Day Landing Beaches - Norwegian Star	4601	9	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
66	4	1679372	D-Day Landing Beaches - Nieuw Statendam	4525	14	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
67	4	1679404	D-Day Landing Beaches - Majestic Princess	4560	11	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
68	4	1853330	Ticket for Shared ShorEX Tour	4634	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
69	4	1869384	MS Nieuw Statendam -9h Tour	4641	14	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
70	4	1928897	7-Hour D-Day Shared Tour	4571	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
71	4	1679402	D-Day Landing Beaches - Norwegian Sky	4561	12	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
72	4	1831111	D-Day Landing Beaches - Norwegian Sun	4528	7	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
73	4	1915661	D-Day Landing Beaches - Norwegian Sky (July 8)	4656	12	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
74	4	1942169	D-Day Landing Beaches - Nieuw Statendam (Apr 16)	\N	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252
75	5	1220390	Shared Tour	4311	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=753769
76	5	1722571	7 hour Shared Tour	\N	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=753769
77	6	1956895	Honfleur and Deauville - Sapphire Princess	4689	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
78	6	1957042	Honfleur and Deauville - Oceana Marina	4691	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
79	6	1957073	Honfleur and Deauville - Liberty of the Seas	4692	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
80	6	1957130	Honfleur and Deauville - Carnival Legend	4693	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
81	6	1661989	Honfleur and Deauville - Majestic Princess	4549	11	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
82	6	1957141	Honfleur and Deauville - Crown Princess	4694	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
83	6	1957175	Honfleur and Deauville - Oceana Sirena	4695	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
84	6	1957221	Honfleur and Deauville - Norwegian Star	4696	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
85	6	1957236	Honfleur and Deauville - Celebrity Apex	4697	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
86	6	1244901	Ticket for Shared Tour	3251	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
87	6	1677932	Honfleur and Deauville - Celebrity Eclipse	4551	13	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
88	6	1957261	Honfleur and Deauville - MS Nieuw Statendam	4698	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
89	6	1957277	Honfleur and Deauville - Sky Princess	4699	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
90	6	1957294	Honfleur and Deauville - Oceania Insignia	4700	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
91	6	1351272	Private Tour	4452	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
92	6	1661958	Honfleur and Deauville - Norwegian Sun	4690	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
93	6	1661991	Honfleur and Deauville - Norwegian Sky	4550	12	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
94	6	1677934	Honfleur and Deauville - Oceania Vista	4552	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105
95	7	1504924	Mont Saint-Michel: Guided Shore Excursion From Le Havre	4453	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=968068
96	7	1679485	2026 August 28th - ONLY Celebrity Eclipse	4558	13	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=968068
97	7	1679486	2026 July 8th - Norwegian Sky	4557	12	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=968068
98	7	1679488	2026 July 8th - Majestic Princess	4556	11	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=968068
99	7	1883184	Mont Saint Michel Only for Majestic Princess	4644	11	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=968068
100	7	1905371	11h Shared Tour Ticket	4653	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=968068
101	8	1679461	2026 July 8th - Majestic Princess	4556	11	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=850090
102	8	1679465	2026 July 8th - Norwegian Sky	4557	12	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=850090
103	8	1679467	2026 August 28th - ONLY Celebrity Eclipse	4558	13	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=850090
104	8	1883188	Mont Saint Michel Only for Majestic Princess	4644	11	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=850090
105	8	1343486	From Le Havre Port: Mont St Michel Shore Excursion	4453	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=850090
106	8	1905367	11h Shared Tour Ticket	4653	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=850090
107	9	1478262	8-Hour Guided Shore Excursion in Bordeaux	4410	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=949145
108	9	1506365	7-Hour Guided Shore Excursion in Bordeaux	4411	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=949145
109	10	1472881	Bordeaux on Your Own Tour from Le Verdon for Cruise Ships (Round)	4404	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=945451
110	10	1472892	Bordeaux on Your Own Tour from Le Verdon for Cruise Ships (Round for bigger)	4405	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=945451
111	10	1472903	Bordeaux on Your Own Tour from Le Verdon for Cruise Ships (Round for Virgin)	4405	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=945451
112	10	1472910	Bordeaux on Your Own Tour (cheaperoption)	4406	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=945451
113	11	1333779	Private Tour (Giverny & Rouen)	\N	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=843160
114	11	1915473	Ticket for Shore Excursion	\N	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=843160
115	11	1915481	Ticket For 2026 July 8th- Norwegian Sky	\N	\N	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=843160
117	13	\N	Ticket for a Shared ShorEX	4634	\N	https://supplier.viator.com/product/63772P138
118	14	\N	Ticket for a Shared ShorEX	4634	\N	https://supplier.viator.com/product/63772P251
119	15	\N	Ticket for a Shared ShorEX	4634	\N	https://supplier.viator.com/product/63772P250
120	12	\N	Sky Princess	4630	1	https://supplier.viator.com/product/63772P113
121	13	\N	Sky Princess - shared tour	4630	1	https://supplier.viator.com/product/63772P138
122	14	\N	Sky Princess - Shared Tour	4630	1	https://supplier.viator.com/product/63772P251
123	15	\N	Sky Princess - shared tour	4630	1	https://supplier.viator.com/product/63772P250
124	12	\N	Oceania Insignia	4629	2	https://supplier.viator.com/product/63772P113
125	13	\N	Oceania Insignia - shared tour	4629	2	https://supplier.viator.com/product/63772P138
126	14	\N	Oceania Insignia - Shared Tour	4629	2	https://supplier.viator.com/product/63772P251
127	15	\N	Oceania Insignia - shared tour	4629	2	https://supplier.viator.com/product/63772P250
128	12	\N	Carnival Legend	4628	3	https://supplier.viator.com/product/63772P113
129	13	\N	Carnival Legend - shared tour	4628	3	https://supplier.viator.com/product/63772P138
130	14	\N	Carnival Legend - Shared Tour	4628	3	https://supplier.viator.com/product/63772P251
131	15	\N	Carnival Legend - shared tour	4628	3	https://supplier.viator.com/product/63772P250
132	12	\N	Celebrity Apex	4623	4	https://supplier.viator.com/product/63772P113
133	13	\N	Celebrity Apex - shared tour	4623	4	https://supplier.viator.com/product/63772P138
134	14	\N	Celebrity Apex - Shared Tour	4623	4	https://supplier.viator.com/product/63772P251
135	15	\N	Celebrity Apex - shared tour	4623	4	https://supplier.viator.com/product/63772P250
136	12	\N	Oceana Sirena	4622	5	https://supplier.viator.com/product/63772P113
137	13	\N	Oceana Sirena - shared tour	4622	5	https://supplier.viator.com/product/63772P138
138	14	\N	Oceana Sirena - Shared Tour	4622	5	https://supplier.viator.com/product/63772P251
139	15	\N	Oceana Sirena - shared tour	4622	5	https://supplier.viator.com/product/63772P250
140	12	\N	Crown Princess	4621	6	https://supplier.viator.com/product/63772P113
141	13	\N	Crown Princess - shared tour	4621	6	https://supplier.viator.com/product/63772P138
142	14	\N	Crown Princess - Shared Tour	4621	6	https://supplier.viator.com/product/63772P251
143	15	\N	Crown Princess - shared tour	4621	6	https://supplier.viator.com/product/63772P250
144	12	\N	Norwegian Sun	4620	7	https://supplier.viator.com/product/63772P113
145	13	\N	Norwegian Sun - shared tour	4620	7	https://supplier.viator.com/product/63772P138
146	14	\N	Norwegian Sun - Shared Tour	4620	7	https://supplier.viator.com/product/63772P251
147	15	\N	Norwegian Sun - shared tour	4620	7	https://supplier.viator.com/product/63772P250
148	12	\N	Liberty of the Seas	4619	8	https://supplier.viator.com/product/63772P113
149	13	\N	Liberty of the Seas - shared	4619	8	https://supplier.viator.com/product/63772P138
150	14	\N	Liberty - Shared Tour	4619	8	https://supplier.viator.com/product/63772P251
151	15	\N	Liberty of the Seas - shared	4619	8	https://supplier.viator.com/product/63772P250
152	12	\N	Norwegian Star	4618	9	https://supplier.viator.com/product/63772P113
153	13	\N	Norwegian Star - shared tour	4618	9	https://supplier.viator.com/product/63772P138
154	14	\N	Norwegian Star - Shared Tour	4618	9	https://supplier.viator.com/product/63772P251
155	15	\N	Norwegian Star - shared tour	4618	9	https://supplier.viator.com/product/63772P250
156	12	\N	Sapphire Princess	4617	10	https://supplier.viator.com/product/63772P113
157	13	\N	Sapphire Princess shared tour	4617	10	https://supplier.viator.com/product/63772P138
158	14	\N	Sapphire Princess -Shared Tour	4617	10	https://supplier.viator.com/product/63772P251
159	15	\N	Sapphire Princess shared tour	4617	10	https://supplier.viator.com/product/63772P250
160	12	\N	Majestic Princess	4533	11	https://supplier.viator.com/product/63772P113
161	13	\N	Majestic Princess-shared tour	4533	11	https://supplier.viator.com/product/63772P138
162	14	\N	Majestic Princess -Shared Tour	4533	11	https://supplier.viator.com/product/63772P251
163	14	\N	Majestic Princess 2026-07-08	4533	11	https://supplier.viator.com/product/63772P251
164	15	\N	Majestic Princess shared tour	4533	11	https://supplier.viator.com/product/63772P250
165	15	\N	Majestic Princess 2026-07-08	4533	11	https://supplier.viator.com/product/63772P250
166	12	\N	Norwegian Sky	4532	12	https://supplier.viator.com/product/63772P113
167	13	\N	Norwegian Sky - shared tour	4532	12	https://supplier.viator.com/product/63772P138
168	14	\N	Norwegian Sky - Shared Tour	4532	12	https://supplier.viator.com/product/63772P251
169	14	\N	Norwegian Sky 2026-07-08	4532	12	https://supplier.viator.com/product/63772P251
170	15	\N	Norwegian Sky - shared tour	4532	12	https://supplier.viator.com/product/63772P250
171	15	\N	Norwegian Sky 2026-07-08	4532	12	https://supplier.viator.com/product/63772P250
172	13	\N	Carnival Legend - 9h tour	4509	3	https://supplier.viator.com/product/63772P138
173	14	\N	Carnival Legend 18th July 2026	4509	3	https://supplier.viator.com/product/63772P251
174	14	\N	Carnival Legend - 9h tour	4509	3	https://supplier.viator.com/product/63772P251
175	15	\N	Carnival Legend 18th July 2026	4509	3	https://supplier.viator.com/product/63772P250
176	12	\N	Shared Tour Paris Sightseeing	4491	\N	https://supplier.viator.com/product/63772P113
177	13	\N	Shared Tour Paris Sightseeing	4491	\N	https://supplier.viator.com/product/63772P138
178	14	\N	Shared Tour Paris Sightseeing	4491	\N	https://supplier.viator.com/product/63772P251
179	12	\N	Oceania Vista	4486	\N	https://supplier.viator.com/product/63772P113
180	13	\N	Oceania Vista- shared tour	4486	\N	https://supplier.viator.com/product/63772P138
181	14	\N	Oceania Vista-Shared Tour	4486	\N	https://supplier.viator.com/product/63772P251
182	14	\N	Oceania Vista 2026-08-28	4486	\N	https://supplier.viator.com/product/63772P251
183	15	\N	Oceania Vista- shared tour	4486	\N	https://supplier.viator.com/product/63772P250
184	15	\N	Oceania Vista 2026-08-28	4486	\N	https://supplier.viator.com/product/63772P250
185	12	\N	Celebrity Eclipse	4485	13	https://supplier.viator.com/product/63772P113
186	13	\N	Celebrity Eclipse shared tour	4485	13	https://supplier.viator.com/product/63772P138
187	14	\N	Celebrity Eclipse-Shared Tour	4485	13	https://supplier.viator.com/product/63772P251
188	14	\N	Celebrity Eclipse 2026-08-28	4485	13	https://supplier.viator.com/product/63772P251
189	15	\N	Celebrity Eclipse shared tour	4485	13	https://supplier.viator.com/product/63772P250
190	15	\N	Celebrity Eclipse 2026-08-28	4485	13	https://supplier.viator.com/product/63772P250
191	12	\N	Nieuw Statendam	4482	14	https://supplier.viator.com/product/63772P113
192	13	\N	Nieuw Statendam-shared tour	4482	14	https://supplier.viator.com/product/63772P138
193	14	\N	Nieuw Statendam - Shared Tour	4482	14	https://supplier.viator.com/product/63772P251
194	14	\N	Nieuw Statendam 2026-04-16	4482	14	https://supplier.viator.com/product/63772P251
195	15	\N	Nieuw Statendam - shared tour	4482	14	https://supplier.viator.com/product/63772P250
196	15	\N	Nieuw Statendam 2026-04-16	4482	14	https://supplier.viator.com/product/63772P250
197	12	\N	Guided Semi-Private with Car	3401	\N	https://supplier.viator.com/product/63772P113
198	13	\N	Guided Semi-Private w. Cruise	3401	\N	https://supplier.viator.com/product/63772P138
199	14	\N	Guided Semi-Private w. Cruise	3401	\N	https://supplier.viator.com/product/63772P251
200	15	\N	Guided Semi-Private w. Cruise	3401	\N	https://supplier.viator.com/product/63772P250
201	12	\N	Fully Private with Paris Guide	1895	\N	https://supplier.viator.com/product/63772P113
202	13	\N	Fully Private with Paris Guide	1895	\N	https://supplier.viator.com/product/63772P138
203	14	\N	Fully Private with Paris Guide	1895	\N	https://supplier.viator.com/product/63772P251
204	15	\N	Fully Private with Paris Guide	1895	\N	https://supplier.viator.com/product/63772P250
205	16	\N	Norwegian Sky 2026-07-08	4531	12	https://supplier.viator.com/product/63772P156
206	17	\N	Ticket for Norwegian Sky	4531	12	https://supplier.viator.com/product/63772P197
207	16	\N	Majestic Princess 2026-07-08	4530	11	https://supplier.viator.com/product/63772P156
208	17	\N	Ticket for Majestic Princess	4530	11	https://supplier.viator.com/product/63772P197
209	16	\N	Carnival Legend 2026-07-18	4510	3	https://supplier.viator.com/product/63772P156
210	17	\N	Ticket for Carnival Legend	4510	3	https://supplier.viator.com/product/63772P197
211	16	\N	Majestic Princess 2026-04-16	4480	11	https://supplier.viator.com/product/63772P156
212	17	\N	Transfer for Majestic Princess	4480	11	https://supplier.viator.com/product/63772P197
213	16	\N	Nieuw Statendam 2026-04-16	4479	14	https://supplier.viator.com/product/63772P156
214	17	\N	Transfer for Nieuw Statendam	4479	14	https://supplier.viator.com/product/63772P197
215	16	\N	Majestic Princess 2026-06-02	4478	11	https://supplier.viator.com/product/63772P156
216	16	\N	Celebrity Eclipse 2026-08-28	4476	13	https://supplier.viator.com/product/63772P156
217	17	\N	Ticket for Celebrity Eclipse	4476	13	https://supplier.viator.com/product/63772P197
218	16	\N	Oceania Vista 2026-08-28	4475	\N	https://supplier.viator.com/product/63772P156
219	17	\N	Ticket for Oceania Vista	4475	\N	https://supplier.viator.com/product/63772P197
220	16	\N	For Regal Princess 2025-09-15	4472	\N	https://supplier.viator.com/product/63772P156
221	16	\N	For NCL Prima 2025-09-15	4471	\N	https://supplier.viator.com/product/63772P156
222	16	\N	Shared Tour Paris on Your Own	4470	\N	https://supplier.viator.com/product/63772P156
223	16	\N	Ticket for Paris on Your Own	4469	\N	https://supplier.viator.com/product/63772P156
224	17	\N	Round Trip: Le Havre-Paris	4469	\N	https://supplier.viator.com/product/63772P197
225	18	\N	Norwegian Sky - 9 hour tour	4657	12	https://supplier.viator.com/product/63772P174
226	19	\N	Norwegian Sky - 9 hour tour	4657	12	https://supplier.viator.com/product/63772P163
229	18	\N	Majestic Princess - 9 hour tour	4642	11	https://supplier.viator.com/product/63772P174
230	19	\N	Majestic Princess - 9 hour tour	4642	11	https://supplier.viator.com/product/63772P163
231	18	\N	Nieuw Statendam - 9 hour tour	4641	14	https://supplier.viator.com/product/63772P174
232	19	\N	Nieuw Statendam - 9 hour tour	4641	14	https://supplier.viator.com/product/63772P163
233	18	\N	Shared ShorEX Tour Ticket	\N	\N	https://supplier.viator.com/product/63772P174
234	19	\N	Ticket for Shared ShorEX Tour	\N	\N	https://supplier.viator.com/product/63772P163
235	18	\N	Carnival Legend - 9 hour tour	4614	3	https://supplier.viator.com/product/63772P174
236	19	\N	Carnival Legend - 9 hour tour	4614	3	https://supplier.viator.com/product/63772P163
237	18	\N	Celebrity Apex - 10 hour tour	4610	4	https://supplier.viator.com/product/63772P174
238	19	\N	Celebrity Apex - 10 hour tour	4610	4	https://supplier.viator.com/product/63772P163
239	18	\N	Oceana Sirena - 10 hour tour	4609	5	https://supplier.viator.com/product/63772P174
240	19	\N	Oceana Sirena - 10 hour tour	4609	5	https://supplier.viator.com/product/63772P163
241	18	\N	Oceania Insignia - 10 hour tour	4608	2	https://supplier.viator.com/product/63772P174
242	19	\N	Oceania Insignia - 10 hour tour	4608	2	https://supplier.viator.com/product/63772P163
243	18	\N	Crown Princess - 10 hour tour	4607	6	https://supplier.viator.com/product/63772P174
244	19	\N	Crown Princess - 10 hour tour	4607	6	https://supplier.viator.com/product/63772P163
245	18	\N	Carnival Legend - 10 hour tour	4606	3	https://supplier.viator.com/product/63772P174
246	19	\N	Carnival Legend - 10 hour tour	4606	3	https://supplier.viator.com/product/63772P163
247	18	\N	Sky Princess - 10 hour tour	4605	1	https://supplier.viator.com/product/63772P174
248	19	\N	Sky Princess - 10 hour tour	4605	1	https://supplier.viator.com/product/63772P163
249	18	\N	Liberty of the Seas - 10 hour tour	4604	8	https://supplier.viator.com/product/63772P174
250	19	\N	Liberty of the Seas - 10 hour tour	4604	8	https://supplier.viator.com/product/63772P163
251	18	\N	Oceana Marina - 8 hour tour	4603	\N	https://supplier.viator.com/product/63772P174
252	19	\N	Oceana Marina - 8 hour tour	4603	\N	https://supplier.viator.com/product/63772P163
253	18	\N	Sapphire Princess - 10 hour tour	4602	10	https://supplier.viator.com/product/63772P174
254	19	\N	Sapphire Princess - 10 hour tour	4602	10	https://supplier.viator.com/product/63772P163
255	18	\N	Norwegian Star - 10 hour tour	4601	9	https://supplier.viator.com/product/63772P174
256	19	\N	Norwegian Star - 10 hour tour	4601	9	https://supplier.viator.com/product/63772P163
257	18	\N	Oceania Vista - 10 hour tour	4563	\N	https://supplier.viator.com/product/63772P174
258	19	\N	Oceania Vista - 10 hour tour	4563	\N	https://supplier.viator.com/product/63772P163
259	18	\N	Celebrity Eclipse - 10 hour tour	4562	13	https://supplier.viator.com/product/63772P174
260	19	\N	Celebrity Eclipse - 10 hour tour	4562	13	https://supplier.viator.com/product/63772P163
261	18	\N	Majestic Princess - 10 hour tour	4560	11	https://supplier.viator.com/product/63772P174
262	19	\N	Majestic Princess - 10 hour tour	4560	11	https://supplier.viator.com/product/63772P163
263	18	\N	Shared 8h D-Day Tour From Le Havre Port	4559	\N	https://supplier.viator.com/product/63772P174
264	19	\N	Shared 8h D-Day Tour From Le Havre Port	4559	\N	https://supplier.viator.com/product/63772P163
265	18	\N	Norwegian Sun - 10 hour tour	4528	7	https://supplier.viator.com/product/63772P174
266	19	\N	Norwegian Sun - 10 hour tour	4528	7	https://supplier.viator.com/product/63772P163
267	18	\N	Nieuw Statendam - 10 hour tour	4525	14	https://supplier.viator.com/product/63772P174
268	19	\N	Nieuw Statendam - 10 hour tour	4525	14	https://supplier.viator.com/product/63772P163
269	19	\N	Shared D-Day Tour	4495	\N	https://supplier.viator.com/product/63772P163
270	18	\N	Shared 9h D-Day Tour From Le Havre Port	4493	\N	https://supplier.viator.com/product/63772P174
271	19	\N	Shared 9h D-Day Tour From Le Havre Port	4493	\N	https://supplier.viator.com/product/63772P163
272	18	\N	Private Tour of D-Day Beaches Normandy from Le Havre Port	1865	\N	https://supplier.viator.com/product/63772P174
273	19	\N	Private Tour of D-Day Beaches Normandy from Le Havre Port	1865	\N	https://supplier.viator.com/product/63772P163
274	20	\N	7 Hour Shared Tour	4571	\N	https://supplier.viator.com/product/63772P203
275	21	\N	7 Hour Shared Tour	4571	\N	https://supplier.viator.com/product/63772P277
276	20	\N	Private D-Day Tour from the Port of Cherbourg	4321	\N	https://supplier.viator.com/product/63772P203
277	22	\N	Private D-Day Tour from the Port of Cherbourg	4321	\N	https://supplier.viator.com/product/63772P242
278	20	\N	Ticket for a shared tour	4311	\N	https://supplier.viator.com/product/63772P203
279	22	\N	Shared D-Day Tour from the Port of Cherbourg	4571	\N	https://supplier.viator.com/product/63772P242
280	21	\N	Shared D-Day Tour from the Port of Cherbourg	4311	\N	https://supplier.viator.com/product/63772P277
281	23	\N	2026 Aug Oceania Vista	4552	\N	https://supplier.viator.com/product/63772P204
282	24	\N	2026 August 28 Oceania Vista	4552	\N	https://supplier.viator.com/product/63772P254
283	25	\N	2026 August 28 Oceania Vista	4552	\N	https://supplier.viator.com/product/63772P276
284	23	\N	2026 Aug Celebrity Eclipse	4551	13	https://supplier.viator.com/product/63772P204
285	24	\N	2026 August 28  Celebrity Eclipse	4551	13	https://supplier.viator.com/product/63772P254
286	25	\N	2026 August 28  Celebrity Eclipse	4551	13	https://supplier.viator.com/product/63772P276
287	23	\N	2026 July 8 Norwegian Sky	4550	12	https://supplier.viator.com/product/63772P204
288	24	\N	2026 July 8  Norwegian Sky	4550	12	https://supplier.viator.com/product/63772P254
289	25	\N	2026 July 8  Norwegian Sky	4550	12	https://supplier.viator.com/product/63772P276
290	23	\N	2026 July 8 Majestic Princess	4549	11	https://supplier.viator.com/product/63772P204
291	24	\N	2026 July 8  Majestic Princess	4549	11	https://supplier.viator.com/product/63772P254
292	25	\N	2026 July 8 Majestic Princess	4549	11	https://supplier.viator.com/product/63772P276
293	23	\N	2026 June 2  Majestic Princess	4547	11	https://supplier.viator.com/product/63772P204
294	24	\N	2026 June 2  Majestic Princess	4547	11	https://supplier.viator.com/product/63772P254
295	25	\N	2026 June 2  Majestic Princess	4547	11	https://supplier.viator.com/product/63772P276
296	23	\N	Fully Private Tour From Port	4452	\N	https://supplier.viator.com/product/63772P204
297	23	\N	Ticket for Shared ShorEX	\N	\N	https://supplier.viator.com/product/63772P204
298	24	\N	Fully Private Tour From Port	4452	\N	https://supplier.viator.com/product/63772P254
299	25	\N	Fully Private Tour From Port	4452	\N	https://supplier.viator.com/product/63772P276
300	23	\N	Ticket for Shared Tour	3251	\N	https://supplier.viator.com/product/63772P204
301	24	\N	Ticket for Shared Tour	3251	\N	https://supplier.viator.com/product/63772P254
302	25	\N	Ticket for Shared Tour	3251	\N	https://supplier.viator.com/product/63772P276
303	26	\N	11h Shared Tour Ticket	4653	\N	https://supplier.viator.com/product/63772P166
304	27	\N	11h Shared Tour Ticket	4653	\N	https://supplier.viator.com/product/63772P221
305	19	\N	Shared Tour- Majestic Princess	4644	11	https://supplier.viator.com/product/63772P163
306	26	\N	Shared Tour- Majestic Princess	4644	11	https://supplier.viator.com/product/63772P166
307	27	\N	Shared Tour- Majestic Princess	4644	11	https://supplier.viator.com/product/63772P221
308	26	\N	28.08.2026 Celebrity Eclipse	4558	13	https://supplier.viator.com/product/63772P166
309	27	\N	28.08.2026 Celebrity Eclipse	4558	13	https://supplier.viator.com/product/63772P221
310	26	\N	8.07.2026 Norwegian Sky	4557	12	https://supplier.viator.com/product/63772P166
311	27	\N	8.07.2026 Norwegian Sky	4557	12	https://supplier.viator.com/product/63772P221
312	26	\N	8.07.2026 Majestic Princess	4556	11	https://supplier.viator.com/product/63772P166
313	27	\N	8.07.2026 Majestic Princess	4556	11	https://supplier.viator.com/product/63772P221
314	26	\N	Ticket for a Shared Tour	4453	\N	https://supplier.viator.com/product/63772P166
315	27	\N	Ticket for a Shared Tour	4453	\N	https://supplier.viator.com/product/63772P221
316	28	\N	7 Hour Shared Tour	4411	\N	https://supplier.viator.com/product/63772P229
317	29	\N	7 Hour Shared Tour	4411	\N	https://supplier.viator.com/product/63772P235
318	28	\N	8 Hour Shared Tour	4410	\N	https://supplier.viator.com/product/63772P229
319	29	\N	8 Hour Shared Tour	4410	\N	https://supplier.viator.com/product/63772P235
320	30	\N	Round-Trip Shared Transfer	4405	\N	https://supplier.viator.com/product/63772—
321	31	\N	Round-Trip Shared Transfer	4405	\N	https://supplier.viator.com/product/63772P252
322	30	\N	Round Trip Shared Transfer	4404	\N	https://supplier.viator.com/product/63772P226
323	31	\N	Round Trip Shared Transfer	4404	\N	https://supplier.viator.com/product/63772P252
116	12	\N	Ticket for a Shared Tour	4629	\N	https://supplier.viator.com/product/63772P113
227	18	\N	Norwegian Sky - 10 hour tour	4561	12	https://supplier.viator.com/product/63772P174
228	19	\N	Norwegian Sky - 10 hour tour	4561	12	https://supplier.viator.com/product/63772P163
\.


--
-- Data for Name: platform_tour; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.platform_tour (platform_tour_id, platform_id, external_id, name, link, status, tour_id) FROM stdin;
1	2	674024	From Le Havre: Deluxe Paris Tour with Seine River Cruise	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=674024	Bookable	1385
2	2	440548	From Le Havre: Paris with River Cruise Shore Excursion	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=440548	Bookable	1385
3	2	477029	From Le Havre Port: Round-Trip Transfer to Paris by Bus	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=477029	Bookable	1375
4	2	501252	From Le Havre: D-Day Beaches Shore Trip with Packed Lunch	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=501252	Bookable	1345
5	2	753769	From Cherbourg: D-Day Beaches Shore Excursion	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=753769	Bookable	1581
6	2	775105	From Le Havre: Seaside Charms Honfleur and Deauville	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=775105	Bookable	1591
7	2	968068	UNESCO World Heritage: Mont St Michel Tour from Le Havre	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=968068	Bookable	1744
8	2	850090	From Le Havre Port: Mont St Michel Shore Excursion	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=850090	Bookable	1744
9	2	949145	From Le Verdon Cruise Port: Bordeaux Guided Shore Excursion	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=949145	Bookable	1747
10	2	945451	Bordeaux on Your Own Tour from Le Verdon for Cruise Ships	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=945451	Bookable	1745
11	2	843160	From Le Havre: Giverny and Rouen Shore Excursion	https://supplier.getyourguide.com/products/details?page=1&limit=5&tour_id=843160	Bookable	\N
12	3	P113	Best of Paris with River Cruise from Le Havre Cruise Port	https://supplier.viator.com/product/63772P113	Active	1385
13	3	P138	Deluxe Paris Shore Excursion from Le Havre with Seine Cruise	https://supplier.viator.com/product/63772P138	Active	1385
14	3	P251	Le Havre to Paris with Boat Cruise for First-Time Cruise Visitors	https://supplier.viator.com/product/63772P251	Active	1385
15	3	P250	Stress-Free Shore Excursion of Paris with Seine River Cruise	https://supplier.viator.com/product/63772P250	Active	1385
16	3	P156	Paris On Your Own from Le Havre Port with Round Trip Bus Transfer	https://supplier.viator.com/product/63772P156	Active	1375
17	3	P197	From Le Havre Port: "Paris On Your Own" Round-Trip Bus Transfer	https://supplier.viator.com/product/63772P197	Active	1375
18	3	P174	Normandy D-Day Landing Beaches and Lunch from Le Havre Port	https://supplier.viator.com/product/63772P174	Active	1345
20	3	P203	From Cherbourg: D-Day Beaches Shore Excursion	https://supplier.viator.com/product/63772P203	Active	1581
21	3	P277	D-Day Beaches Shore Excursion from Cherbourg Cruise Port	https://supplier.viator.com/product/63772P277	Active	1581
22	3	P242	Hassle-Free Normandy D-Day Shore Trip from Cherbourg Cruise Port	https://supplier.viator.com/product/63772P242	Active	1581
23	3	P204	From Le Havre Breathtaking Honfleur and Deauville Shore Excursion	https://supplier.viator.com/product/63772P204	Active	1591
24	3	P254	Stress-Free Honfleur & Deauville Shore Excursion from Le Havre	https://supplier.viator.com/product/63772P254	Active	1591
25	3	P276	Normandy Coast Shore Excursion: Honfleur & Deauville	https://supplier.viator.com/product/63772P276	Active	1591
26	3	P166	Mont Saint-Michel Shore Excursion from Le Havre with Packed Lunch	https://supplier.viator.com/product/63772P166	Active	1744
27	3	P221	Mont St Michel Shore Excursion from Le Havre Guided Tour & Lunch	https://supplier.viator.com/product/63772P221	Active	1744
28	3	P229	Deluxe Bordeaux Shore Excursion from Le Verdon Cruise Ship Port	https://supplier.viator.com/product/63772P229	Active	1747
29	3	P235	Le Verdon Port to Bordeaux: Culture, Wine & Highlights Shore Trip	https://supplier.viator.com/product/63772P235	Active	1747
31	3	P252	Discover Bordeaux Your Way A Relaxed Day Trip from Le Verdon	https://supplier.viator.com/product/63772P252	Active	1745
19	3	P163	D-Day Beaches Shore Excursion from Le Havre with Packed Lunch	https://supplier.viator.com/product/63772P163	Active	1744
30	3	P226	From Le Verdon: Bordeaux on Your Own Shore Trip for Cruise Ships	https://supplier.viator.com/product/63772P226	Active	1745
\.


--
-- Data for Name: port; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.port (port_id, name) FROM stdin;
1	Le Havre
2	Le Verdon
3	Cherbourg
\.


--
-- Data for Name: pricing; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pricing (pricing_id, shorex_id, platform_id, platform_tour_id, vex_option_id, price, commission_pct, promo_name, promo_pct, platform_status, link, change_status, editor, reviewer, reviewed, review, updated_at) FROM stdin;
1	1	1	\N	\N	152.00	0.1000	\N	\N	Published	https://www.vexperio.com/nova/resources/tours/1385	Changed	Tino	Tino	t	Approved	2026-05-13 08:07:25.826706+00
2	1	3	12	\N	169.00	0.2460	\N	\N	Active	https://supplier.viator.com/product/63772P113	Error	Tino	Tino	f	Pending	2026-05-13 08:07:25.826706+00
3	1	2	1	\N	169.00	0.3710	\N	\N	Bookable	https://supplier.getyourguide.com/products/details?tour_id=674024	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
4	1	4	\N	\N	169.00	0.1000	\N	\N	Pending-QC	\N	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
5	2	1	\N	\N	\N	\N	\N	\N	Published	https://www.vexperio.com/nova/resources/tours/1375	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
6	2	3	\N	\N	129.00	0.2460	\N	\N	Active	https://supplier.viator.com/product/63772P195	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
7	2	2	3	\N	129.00	\N	\N	\N	Bookable	https://supplier.getyourguide.com/products/details?tour_id=477029	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
8	2	4	\N	\N	129.00	\N	\N	\N	Pending-QC	\N	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
9	3	1	\N	\N	179.00	0.1000	\N	\N	Published	https://www.vexperio.com/nova/resources/tours/1345	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
10	3	3	18	\N	199.00	0.2460	\N	\N	Active	https://supplier.viator.com/product/63772P174	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
11	3	2	4	\N	199.00	0.3710	\N	\N	Bookable	https://supplier.getyourguide.com/products/details?tour_id=501252	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
12	3	4	\N	\N	199.00	0.1000	\N	\N	Pending-QC	\N	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
13	4	1	\N	\N	134.00	0.1000	\N	\N	Published	https://www.vexperio.com/nova/resources/tours/1581	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
14	4	3	20	\N	149.00	0.2230	\N	\N	Active	https://supplier.viator.com/product/63772P203	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
15	4	2	5	\N	149.00	0.3710	\N	\N	Bookable	https://supplier.getyourguide.com/products/details?tour_id=501252	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
16	4	4	\N	\N	149.00	0.1000	\N	\N	Bookable	\N	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
17	5	1	\N	\N	116.00	0.1000	\N	\N	Published	https://www.vexperio.com/nova/resources/tours/1591	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
18	5	3	23	\N	129.00	0.2460	\N	\N	Active	https://supplier.viator.com/product/63772P204	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
19	5	2	6	\N	129.00	0.3720	\N	\N	Bookable	https://supplier.getyourguide.com/products/details?tour_id=775105	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
20	5	4	\N	\N	129.00	0.1000	\N	\N	Pending-QC	\N	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
21	6	1	\N	\N	143.00	0.1000	\N	\N	Published	https://www.vexperio.com/nova/resources/tours/1744	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
22	6	3	\N	\N	190.80	0.2460	\N	\N	Active	https://supplier.viator.com/product/63772P166	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
23	6	2	7	\N	190.80	0.3710	\N	\N	Bookable	https://supplier.getyourguide.com/products/details?tour_id=968068	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
24	6	4	\N	\N	190.80	0.1000	\N	\N	Bookable	\N	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
25	7	1	\N	\N	134.00	0.1000	\N	\N	Published	https://www.vexperio.com/nova/resources/tours/1747	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
26	7	3	28	\N	149.00	0.2691	\N	\N	Active	https://supplier.viator.com/product/63772P229	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
27	7	2	9	\N	149.00	0.3710	\N	\N	Bookable	https://supplier.getyourguide.com/products/details?tour_id=949145	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
28	7	4	\N	\N	149.00	0.1000	\N	\N	Pending-QC	\N	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
29	8	1	\N	\N	109.00	\N	\N	\N	Published	https://www.vexperio.com/nova/resources/tours/1745	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
30	8	3	\N	\N	119.00	0.2591	\N	\N	Active	https://supplier.viator.com/product/63772P226	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
31	8	2	10	\N	119.00	\N	\N	\N	Rejected	https://supplier.getyourguide.com/products/details?tour_id=945451	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
32	8	4	\N	\N	119.00	\N	\N	\N	Bookable	\N	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
33	9	1	\N	\N	125.00	0.1010	\N	\N	Published	https://www.vexperio.com/nova/resources/tours/1385	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
34	9	2	11	\N	\N	0.3720	\N	\N	Bookable	https://supplier.getyourguide.com/products/details?tour_id=843160	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
35	9	4	\N	\N	\N	0.1010	\N	\N	Pending-QC	\N	\N	\N	\N	f	\N	2026-05-13 08:07:25.826706+00
\.


--
-- Data for Name: pricing_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pricing_history (history_id, pricing_id, shorex_id, platform_id, platform_tour_id, price, commission_pct, platform_status, change_status, editor, reviewer, review, snapshotted_at) FROM stdin;
\.


--
-- Data for Name: schedule_platform_entry; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.schedule_platform_entry (entry_id, schedule_id, vex_option_id, platform_option_id, expected_price, entry_status, edit_status, editor, reviewer, reviewed, review) FROM stdin;
1	1	1895	\N	\N	Opened	edited	Tino	Tino	t	All Good
2	2	4469	\N	116.00	Opened	Pending	Tino	Tino	f	Pending
3	3	1865	\N	\N	Opened	\N	\N	\N	f	\N
4	4	4533	\N	152.00	Opened	\N	\N	\N	f	\N
5	5	4530	\N	116.00	Opened	\N	\N	\N	f	\N
6	6	4642	\N	179.00	Opened	\N	\N	\N	t	\N
7	7	1865	\N	\N	Opened	\N	\N	\N	f	\N
8	8	3251	\N	129.50	Done	edited	Julia	Tino	t	All Good
9	9	1895	\N	\N	Opened	\N	\N	\N	f	\N
10	10	4453	\N	143.00	Opened	\N	\N	\N	f	\N
11	11	4532	\N	152.00	Opened	\N	\N	\N	f	\N
12	12	4531	\N	116.00	Opened	\N	\N	\N	f	\N
13	13	4657	\N	179.00	Opened	\N	\N	\N	f	\N
15	15	4533	\N	152.00	Opened	\N	\N	\N	f	\N
16	16	4530	\N	116.00	Opened	\N	\N	\N	f	\N
17	17	4644	\N	143.00	Opened	\N	\N	\N	f	\N
18	18	4642	\N	179.00	Opened	\N	\N	\N	f	\N
20	18	4642	\N	179.00	Opened	\N	\N	\N	f	\N
21	21	4617	\N	152.00	Opened	\N	\N	\N	f	\N
22	22	4469	\N	116.00	Opened	\N	\N	\N	f	\N
23	23	4453	\N	143.00	closed	\N	\N	\N	f	\N
24	24	4602	\N	179.00	Opened	\N	\N	\N	f	\N
25	25	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
26	26	4410	\N	134.00	Rescheduled	edited	Tino	Tino	t	All Good
27	27	4410	\N	134.00	Opened	edited	Julia	Tino	t	All Good
28	28	4532	\N	152.00	closed	All Good	\N	\N	f	\N
29	29	4531	\N	116.00	closed	All Good	\N	\N	f	\N
30	30	4557	\N	143.00	closed	All Good	\N	\N	f	\N
31	31	4657	\N	179.00	Opened	\N	\N	\N	f	\N
32	32	3251	\N	129.50	Cancelled	edited	Julia	Tino	t	All Good
33	33	4618	\N	152.00	Opened	\N	\N	\N	f	\N
34	34	4469	\N	116.00	Opened	\N	\N	\N	f	\N
35	35	4453	\N	143.00	Opened	\N	\N	\N	f	\N
36	36	4601	\N	179.00	Opened	\N	\N	\N	f	\N
37	37	3251	\N	129.50	Cancelled	edited	Julia	Tino	t	All Good
38	38	4311	\N	134.00	Opened	\N	\N	\N	f	\N
39	39	4533	\N	152.00	Opened	\N	\N	\N	f	\N
40	40	4530	\N	116.00	Opened	\N	\N	\N	f	\N
41	41	4644	\N	143.00	Opened	\N	\N	\N	f	\N
42	42	4642	\N	179.00	closed	edited	Tino	\N	f	\N
43	43	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
44	42	4642	\N	179.00	closed	edited	\N	\N	f	\N
45	45	4532	\N	152.00	Opened	\N	\N	\N	f	\N
46	46	4531	\N	116.00	Opened	\N	\N	\N	f	\N
47	47	4557	\N	143.00	Opened	\N	\N	\N	f	\N
48	48	4657	\N	179.00	Opened	\N	\N	\N	f	\N
50	50	4533	\N	152.00	Opened	\N	\N	\N	f	\N
51	51	4530	\N	116.00	Opened	\N	\N	\N	f	\N
52	52	4644	\N	143.00	Opened	\N	\N	\N	f	\N
53	53	4642	\N	179.00	Opened	\N	\N	\N	f	\N
55	53	4642	\N	179.00	Opened	\N	\N	\N	f	\N
56	56	1895	\N	\N	Opened	\N	\N	\N	f	\N
57	57	4469	\N	116.00	Opened	\N	\N	\N	f	\N
58	58	1865	\N	\N	Opened	\N	\N	\N	f	\N
59	59	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
60	60	4311	\N	134.00	Opened	\N	\N	\N	f	\N
61	61	4311	\N	134.00	Opened	\N	\N	\N	f	\N
62	62	4619	\N	152.00	Opened	\N	\N	\N	f	\N
63	63	4469	\N	116.00	Opened	\N	\N	\N	f	\N
64	64	4453	\N	143.00	Opened	\N	\N	\N	f	\N
65	65	4604	\N	179.00	Opened	\N	\N	\N	f	\N
66	66	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
67	67	4533	\N	152.00	Opened	\N	\N	\N	f	\N
68	68	4530	\N	116.00	Opened	\N	\N	\N	f	\N
69	69	4644	\N	143.00	Opened	\N	\N	\N	f	\N
70	70	\N	\N	179.00	Opened	\N	\N	\N	f	\N
71	71	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
72	70	4642	\N	179.00	Opened	\N	\N	\N	f	\N
73	73	4528	\N	179.00	Opened	\N	\N	\N	f	\N
74	74	4620	\N	152.00	Opened	\N	\N	\N	f	\N
75	75	4469	\N	116.00	Opened	\N	\N	\N	f	\N
76	76	4619	\N	152.00	Opened	\N	\N	\N	f	\N
77	77	4469	\N	116.00	Opened	\N	\N	\N	f	\N
78	78	4453	\N	143.00	Opened	\N	\N	\N	f	\N
79	79	4604	\N	179.00	Opened	\N	\N	\N	f	\N
80	80	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
81	81	4533	\N	152.00	Opened	\N	\N	\N	f	\N
82	82	4530	\N	116.00	Opened	\N	\N	\N	f	\N
83	83	4644	\N	143.00	Opened	\N	\N	\N	f	\N
84	84	4642	\N	179.00	Opened	\N	\N	\N	f	\N
86	84	4642	\N	179.00	Opened	\N	\N	\N	f	\N
87	87	4532	\N	152.00	Opened	\N	\N	\N	f	\N
88	88	4531	\N	116.00	Opened	\N	\N	\N	f	\N
89	89	4557	\N	143.00	Opened	\N	\N	\N	f	\N
90	90	4657	\N	179.00	Opened	\N	\N	\N	f	\N
92	92	4628	\N	152.00	Opened	\N	\N	\N	f	\N
93	93	4510	\N	116.00	Opened	\N	\N	\N	f	\N
94	94	4453	\N	143.00	Opened	\N	\N	\N	f	\N
95	95	4614	\N	179.00	Opened	\N	\N	\N	f	\N
96	96	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
97	97	4621	\N	152.00	Opened	\N	\N	\N	f	\N
98	98	4469	\N	116.00	Opened	\N	\N	\N	f	\N
99	99	4453	\N	143.00	Opened	\N	\N	\N	f	\N
100	100	4607	\N	179.00	Opened	\N	\N	\N	f	\N
101	101	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
102	102	4311	\N	134.00	Opened	\N	\N	\N	f	\N
104	104	4622	\N	152.00	Opened	\N	\N	\N	f	\N
105	105	4469	\N	116.00	Opened	\N	\N	\N	f	\N
106	106	4453	\N	143.00	Opened	\N	\N	\N	f	\N
107	107	4609	\N	179.00	Opened	\N	\N	\N	f	\N
108	108	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
109	109	4311	\N	134.00	Opened	\N	\N	\N	f	\N
110	109	4311	\N	134.00	Opened	\N	\N	\N	f	\N
111	111	4533	\N	152.00	Opened	\N	\N	\N	f	\N
112	112	4530	\N	116.00	Opened	\N	\N	\N	f	\N
113	113	4642	\N	179.00	Opened	\N	\N	\N	f	\N
114	114	4533	\N	125.00	Opened	\N	\N	\N	f	\N
115	115	4453	\N	143.00	Opened	\N	\N	\N	f	\N
116	116	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
117	117	1865	\N	\N	Opened	\N	\N	\N	f	\N
118	118	4532	\N	152.00	Opened	\N	\N	\N	f	\N
119	119	4531	\N	116.00	Opened	\N	\N	\N	f	\N
120	120	4657	\N	179.00	Opened	\N	\N	\N	f	\N
121	121	4311	\N	134.00	Opened	\N	\N	\N	f	\N
122	122	4614	\N	179.00	Opened	\N	\N	\N	f	\N
123	123	4628	\N	152.00	Opened	\N	\N	\N	f	\N
124	124	4510	\N	116.00	Opened	\N	\N	\N	f	\N
125	125	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
126	126	4533	\N	152.00	Opened	\N	\N	\N	f	\N
127	127	4530	\N	116.00	Opened	\N	\N	\N	f	\N
128	128	4644	\N	143.00	Opened	\N	\N	\N	f	\N
129	129	4642	\N	179.00	Opened	\N	\N	\N	f	\N
131	129	4642	\N	179.00	Opened	\N	\N	\N	f	\N
132	132	4532	\N	152.00	Opened	\N	\N	\N	f	\N
133	133	4531	\N	116.00	Opened	\N	\N	\N	f	\N
134	134	4557	\N	143.00	Opened	\N	\N	\N	f	\N
135	135	4657	\N	179.00	Opened	\N	\N	\N	f	\N
137	137	4623	\N	152.00	Opened	\N	\N	\N	f	\N
138	138	4469	\N	116.00	Opened	\N	\N	\N	f	\N
139	139	4453	\N	143.00	Opened	\N	\N	\N	f	\N
140	140	4610	\N	179.00	Opened	\N	\N	\N	f	\N
141	141	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
142	142	4533	\N	152.00	Opened	\N	\N	\N	f	\N
143	143	4530	\N	116.00	Opened	\N	\N	\N	f	\N
144	144	4644	\N	143.00	Opened	\N	\N	\N	f	\N
145	145	4642	\N	179.00	Opened	\N	\N	\N	f	\N
146	146	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
147	145	4642	\N	179.00	Opened	\N	\N	\N	f	\N
148	148	4513	\N	134.00	Opened	edited	Julia	Tino	t	All Good
149	149	4410	\N	134.00	Opened	edited	Julia	Tino	t	All Good
150	150	4311	\N	134.00	Opened	\N	\N	\N	f	\N
151	151	4628	\N	152.00	Opened	\N	\N	\N	f	\N
152	152	4614	\N	116.00	Opened	\N	\N	\N	f	\N
153	153	4453	\N	143.00	Opened	\N	\N	\N	f	\N
154	154	4614	\N	179.00	Opened	\N	\N	\N	f	\N
155	155	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
156	156	4533	\N	152.00	Opened	\N	\N	\N	f	\N
157	157	4642	\N	116.00	Opened	\N	\N	\N	f	\N
158	158	4644	\N	143.00	Opened	\N	\N	\N	f	\N
159	159	4642	\N	179.00	Opened	\N	\N	\N	f	\N
161	159	4642	\N	179.00	Opened	\N	\N	\N	f	\N
162	162	4469	\N	116.00	Opened	\N	\N	\N	f	\N
163	163	4619	\N	152.00	Opened	\N	\N	\N	f	\N
164	168	4604	\N	143.00	Opened	\N	\N	\N	f	\N
165	165	4604	\N	179.00	Opened	\N	\N	\N	f	\N
166	165	4604	\N	179.00	Opened	\N	\N	\N	f	\N
167	167	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
168	168	4453	\N	143.00	Opened	\N	\N	\N	f	\N
169	169	4532	\N	152.00	Opened	\N	\N	\N	f	\N
170	170	4657	\N	116.00	Opened	\N	\N	\N	f	\N
171	171	4557	\N	143.00	Opened	\N	\N	\N	f	\N
172	172	4657	\N	179.00	Opened	\N	\N	\N	f	\N
174	174	4532	\N	152.00	Opened	\N	\N	\N	f	\N
175	175	4657	\N	116.00	Opened	\N	\N	\N	f	\N
176	176	4557	\N	143.00	Opened	\N	\N	\N	f	\N
177	177	4657	\N	179.00	Opened	\N	\N	\N	f	\N
179	179	4533	\N	152.00	Opened	\N	\N	\N	f	\N
180	180	4642	\N	116.00	Opened	\N	\N	\N	f	\N
181	181	4644	\N	143.00	Opened	\N	\N	\N	f	\N
182	182	4642	\N	179.00	Opened	\N	\N	\N	f	\N
184	182	4642	\N	179.00	Opened	\N	\N	\N	f	\N
185	185	4485	\N	152.00	Opened	\N	\N	\N	f	\N
186	186	4562	\N	116.00	Opened	\N	\N	\N	f	\N
187	187	4558	\N	143.00	Opened	\N	\N	\N	f	\N
188	188	4562	\N	179.00	Opened	\N	\N	\N	f	\N
189	189	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
190	190	1895	\N	\N	Opened	\N	\N	\N	f	\N
191	191	1865	\N	116.00	Opened	\N	\N	\N	f	\N
192	192	4653	\N	143.00	Opened	\N	\N	\N	f	\N
193	193	1865	\N	\N	Opened	\N	\N	\N	f	\N
194	194	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
195	195	4628	\N	152.00	Opened	\N	\N	\N	f	\N
196	196	4614	\N	116.00	Opened	\N	\N	\N	f	\N
197	197	4453	\N	143.00	Opened	\N	\N	\N	f	\N
198	198	4614	\N	179.00	Opened	\N	\N	\N	f	\N
199	199	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
200	200	4410	\N	134.00	Opened	edited	Julia	Tino	t	All Good
201	201	4533	\N	152.00	Opened	\N	\N	\N	f	\N
202	202	4530	\N	116.00	Opened	\N	\N	\N	f	\N
203	203	4642	\N	143.00	Opened	\N	\N	\N	f	\N
204	204	4642	\N	179.00	Opened	\N	\N	\N	f	\N
205	205	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
206	204	4642	\N	179.00	Opened	\N	\N	\N	f	\N
207	207	4311	\N	134.00	Opened	\N	\N	\N	f	\N
208	208	4533	\N	152.00	Opened	\N	\N	\N	f	\N
209	209	4530	\N	116.00	Opened	\N	\N	\N	f	\N
210	210	4644	\N	143.00	Opened	\N	\N	\N	f	\N
211	211	4657	\N	179.00	Opened	\N	\N	\N	f	\N
213	211	4657	\N	179.00	Opened	\N	\N	\N	f	\N
214	214	4619	\N	152.00	Opened	\N	\N	\N	f	\N
215	215	4469	\N	116.00	Opened	\N	\N	\N	f	\N
216	216	4453	\N	143.00	Opened	\N	\N	\N	f	\N
217	217	4604	\N	179.00	Opened	\N	\N	\N	f	\N
218	218	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
219	219	4410	\N	134.00	Opened	edited	Julia	Tino	t	All Good
220	220	4629	\N	152.00	Opened	\N	\N	\N	f	\N
221	221	4469	\N	116.00	Opened	\N	\N	\N	f	\N
222	222	4453	\N	143.00	Opened	\N	\N	\N	f	\N
223	223	4608	\N	179.00	Opened	\N	\N	\N	f	\N
224	224	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
225	225	4619	\N	152.00	Opened	\N	\N	\N	f	\N
226	226	4469	\N	116.00	Opened	\N	\N	\N	f	\N
227	227	4453	\N	143.00	Opened	\N	\N	\N	f	\N
228	228	4604	\N	179.00	Opened	\N	\N	\N	f	\N
229	229	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
230	230	4630	\N	152.00	Opened	\N	\N	\N	f	\N
231	231	4469	\N	116.00	Opened	\N	\N	\N	f	\N
232	232	4453	\N	143.00	Opened	\N	\N	\N	f	\N
233	233	4605	\N	179.00	Opened	\N	\N	\N	f	\N
234	234	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
235	235	4618	\N	152.00	Opened	\N	\N	\N	f	\N
236	236	4469	\N	116.00	Opened	\N	\N	\N	f	\N
237	237	4453	\N	143.00	Opened	\N	\N	\N	f	\N
238	238	4601	\N	179.00	Opened	\N	\N	\N	f	\N
239	239	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
240	240	4618	\N	125.00	Opened	\N	\N	\N	f	\N
241	241	4619	\N	152.00	Opened	\N	\N	\N	f	\N
242	242	4531	\N	116.00	Opened	\N	\N	\N	f	\N
243	243	4453	\N	143.00	Opened	\N	\N	\N	f	\N
244	244	4604	\N	179.00	Opened	\N	\N	\N	f	\N
245	245	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
246	246	4311	\N	134.00	Opened	\N	\N	\N	f	\N
247	247	4410	\N	134.00	Opened	edited	Julia	Tino	t	All Good
248	248	4311	\N	134.00	Opened	\N	\N	\N	f	\N
249	249	4453	\N	143.00	Opened	\N	\N	\N	f	\N
250	250	4619	\N	152.00	Opened	\N	\N	\N	f	\N
251	251	4469	\N	116.00	Opened	\N	\N	\N	f	\N
252	252	4604	\N	179.00	Opened	\N	\N	\N	f	\N
253	253	3251	\N	129.50	closed	All Good	Tino	Tino	t	All Good
254	254	4620	\N	152.00	Opened	\N	\N	\N	f	\N
255	255	4469	\N	116.00	Opened	\N	\N	\N	f	\N
256	256	4453	\N	143.00	Opened	\N	\N	\N	f	\N
257	257	4528	\N	179.00	Opened	\N	\N	\N	f	\N
258	258	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
259	259	3251	\N	116.00	Opened	edited	Julia	Tino	f	\N
260	260	4469	\N	116.00	Opened	\N	\N	\N	f	\N
261	261	4453	\N	143.00	Opened	\N	\N	\N	f	\N
262	262	4605	\N	179.00	Opened	\N	\N	\N	f	\N
263	263	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
264	264	3251	\N	116.00	Opened	edited	Julia	Tino	f	\N
265	265	4618	\N	152.00	Opened	edited	Julia	Tino	t	All Good
266	266	4469	\N	129.00	Opened	edited	Julia	Tino	t	Clarification Needed
267	267	4453	\N	143.00	Opened	edited	Julia	Tino	t	All Good
268	268	4601	\N	179.00	Opened	edited	Julia	Tino	t	Clarification Needed
269	269	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
270	270	4618	\N	152.00	Opened	\N	\N	\N	f	\N
271	271	4469	\N	116.00	Opened	\N	\N	\N	f	\N
272	272	4453	\N	143.00	Opened	\N	\N	\N	f	\N
273	273	4601	\N	179.00	Opened	\N	\N	\N	f	\N
274	274	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
275	275	1895	\N	\N	Opened	\N	\N	\N	f	\N
276	276	4469	\N	116.00	Opened	\N	\N	\N	f	\N
277	277	4453	\N	143.00	Opened	\N	\N	\N	f	\N
278	278	1865	\N	\N	Opened	\N	\N	\N	f	\N
279	279	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
280	280	4311	\N	134.00	Opened	\N	\N	\N	f	\N
281	281	1895	\N	\N	Opened	\N	\N	\N	f	\N
282	282	4469	\N	116.00	Opened	\N	\N	\N	f	\N
283	283	4453	\N	143.00	Opened	\N	\N	\N	f	\N
284	284	1865	\N	\N	Opened	\N	\N	\N	f	\N
285	285	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
286	92	4628	\N	0.00	Opened	\N	\N	\N	t	\N
287	93	4510	\N	0.00	Opened	\N	\N	\N	t	\N
288	94	4453	\N	0.00	Opened	\N	\N	\N	t	\N
289	95	4606	\N	0.00	Opened	\N	\N	\N	t	\N
290	96	3251	\N	129.50	Opened	edited	Julia	Tino	t	All Good
291	1	1895	\N	0.00	Opened	Changed	Tino	Tino	t	All Good
292	2	4469	\N	0.00	Opened	Error	Tino	Tino	f	Pending
293	3	4525	\N	143.20	Opened	Changed	Tino	\N	f	\N
294	4	4533	\N	169.00	Opened	\N	\N	\N	f	\N
295	5	4530	\N	0.00	Opened	\N	\N	\N	f	\N
296	6	4642	\N	199.00	Opened	\N	\N	\N	t	\N
297	7	\N	\N	143.20	Opened	Changed	Tino	\N	f	\N
298	8	3251	\N	129.00	Done	Changed	Tino	Tino	t	All Good
299	9	1895	\N	0.00	Opened	\N	\N	\N	f	\N
300	10	4453	\N	0.00	Opened	\N	\N	\N	f	\N
301	11	4532	\N	169.00	Opened	\N	\N	\N	f	\N
302	12	4531	\N	0.00	Opened	\N	\N	\N	f	\N
303	13	4657	\N	199.00	Opened	\N	\N	\N	f	\N
305	15	4533	\N	169.00	Opened	\N	\N	\N	f	\N
306	16	4530	\N	0.00	Opened	\N	\N	\N	f	\N
307	17	4560	\N	143.20	Opened	Changed	Tino	\N	f	\N
308	18	4642	\N	199.00	Opened	\N	\N	\N	f	\N
310	18	4642	\N	199.00	Opened	\N	\N	\N	f	\N
311	21	4617	\N	169.00	Opened	\N	\N	\N	f	\N
312	22	4469	\N	0.00	Opened	\N	\N	\N	f	\N
313	23	4453	\N	0.00	closed	\N	\N	\N	f	\N
314	24	4602	\N	199.00	Opened	\N	\N	\N	f	\N
315	25	3251	\N	129.00	closed	Changed	Julia	Tino	t	All Good
316	26	4410	\N	149.00	Rescheduled	OK	Tino	Tino	t	All Good
317	27	4410	\N	149.00	Rescheduled	Changed	Tino	Tino	t	All Good
318	28	4532	\N	169.00	Opened	\N	\N	\N	f	\N
319	29	4531	\N	0.00	Opened	\N	\N	\N	f	\N
320	30	4557	\N	0.00	Opened	\N	\N	\N	f	\N
321	31	4657	\N	199.00	Opened	\N	\N	\N	f	\N
322	32	3251	\N	129.00	Cancelled	Changed	Julia	Tino	t	All Good
323	33	4618	\N	169.00	Opened	\N	\N	\N	f	\N
324	34	4469	\N	0.00	Opened	\N	\N	\N	f	\N
325	35	4453	\N	0.00	Opened	\N	\N	\N	f	\N
326	36	4601	\N	199.00	Opened	\N	\N	\N	f	\N
327	37	3251	\N	129.00	Cancelled	Changed	Julia	Tino	t	All Good
328	38	4311	\N	0.00	Opened	\N	\N	\N	f	\N
329	39	4533	\N	169.00	Opened	\N	\N	\N	f	\N
330	40	4530	\N	0.00	Opened	\N	\N	\N	f	\N
331	41	4560	\N	143.20	Opened	Changed	Tino	\N	f	\N
332	42	4642	\N	199.00	Opened	\N	\N	\N	f	\N
333	43	3251	\N	129.00	closed	Changed	Julia	Tino	t	All Good
334	42	4642	\N	199.00	Opened	\N	\N	\N	f	\N
335	45	4532	\N	169.00	Opened	\N	\N	\N	f	\N
336	46	4531	\N	0.00	Opened	\N	\N	\N	f	\N
337	47	4557	\N	0.00	Opened	\N	\N	\N	f	\N
338	48	4657	\N	199.00	Opened	\N	\N	\N	f	\N
340	50	4533	\N	169.00	Opened	\N	\N	\N	f	\N
341	51	4530	\N	0.00	Opened	\N	\N	\N	f	\N
342	52	4560	\N	143.20	Opened	Changed	Tino	\N	f	\N
343	53	4642	\N	199.00	Opened	\N	\N	\N	f	\N
345	71	3251	\N	129.00	Opened	OK	Filip	Tino	t	All Good
346	53	4642	\N	199.00	Opened	\N	\N	\N	f	\N
347	56	1895	\N	0.00	Opened	\N	\N	\N	f	\N
348	57	4469	\N	0.00	Opened	\N	\N	\N	f	\N
349	58	4603	\N	143.20	Opened	Changed	Tino	\N	f	\N
350	59	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
351	60	4311	\N	0.00	Opened	\N	\N	\N	f	\N
352	61	4311	\N	0.00	Opened	\N	\N	\N	f	\N
353	62	4619	\N	169.00	Opened	\N	\N	\N	f	\N
354	63	4469	\N	0.00	Opened	\N	\N	\N	f	\N
355	64	4453	\N	0.00	Opened	\N	\N	\N	f	\N
356	65	4604	\N	199.00	Opened	\N	\N	\N	f	\N
357	66	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
358	67	4533	\N	169.00	Opened	\N	\N	\N	f	\N
359	68	4530	\N	0.00	Opened	\N	\N	\N	f	\N
360	69	4560	\N	143.20	Opened	Changed	Tino	\N	f	\N
361	70	4642	\N	199.00	Opened	\N	\N	\N	f	\N
362	71	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
363	70	4642	\N	199.00	Opened	\N	\N	\N	f	\N
364	73	4528	\N	199.00	Opened	\N	\N	\N	f	\N
365	74	4620	\N	169.00	Opened	\N	\N	\N	f	\N
366	75	4469	\N	0.00	Opened	\N	\N	\N	f	\N
367	76	4619	\N	169.00	Opened	\N	\N	\N	f	\N
368	77	4469	\N	0.00	Opened	\N	\N	\N	f	\N
369	78	4453	\N	0.00	Opened	\N	\N	\N	f	\N
370	79	4604	\N	199.00	Opened	\N	\N	\N	f	\N
371	80	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
372	81	4533	\N	169.00	Opened	\N	\N	\N	f	\N
373	82	4530	\N	0.00	Opened	\N	\N	\N	f	\N
374	83	4560	\N	143.20	Opened	Changed	Tino	\N	f	\N
375	84	4642	\N	199.00	Opened	\N	\N	\N	f	\N
377	84	4642	\N	199.00	Opened	\N	\N	\N	f	\N
378	87	4532	\N	169.00	Opened	\N	\N	\N	f	\N
379	88	4531	\N	0.00	Opened	\N	\N	\N	f	\N
380	89	4557	\N	0.00	Opened	\N	\N	\N	f	\N
381	90	4657	\N	199.00	Opened	\N	\N	\N	f	\N
383	116	3251	\N	129.00	Opened	OK	Filip	Tino	t	All Good
384	92	4628	\N	169.00	Opened	\N	\N	\N	f	\N
385	93	4510	\N	0.00	Opened	\N	\N	\N	f	\N
386	94	4453	\N	0.00	Opened	\N	\N	\N	f	\N
387	95	4614	\N	199.00	Opened	\N	\N	\N	f	\N
388	96	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
389	97	4621	\N	169.00	Opened	\N	\N	\N	f	\N
390	98	4469	\N	0.00	Opened	\N	\N	\N	f	\N
391	99	4453	\N	0.00	Opened	\N	\N	\N	f	\N
392	100	4607	\N	199.00	Opened	\N	\N	\N	f	\N
393	101	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
394	102	4311	\N	0.00	Opened	\N	\N	\N	f	\N
396	104	4622	\N	169.00	Opened	\N	\N	\N	f	\N
397	105	4469	\N	0.00	Opened	\N	\N	\N	f	\N
398	106	4453	\N	0.00	Opened	\N	\N	\N	f	\N
399	107	4609	\N	199.00	Opened	\N	\N	\N	f	\N
400	108	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
401	109	4311	\N	0.00	Opened	\N	\N	\N	f	\N
402	109	4311	\N	0.00	Opened	\N	\N	\N	f	\N
403	111	4533	\N	169.00	Opened	\N	\N	\N	f	\N
404	112	4530	\N	0.00	Opened	\N	\N	\N	f	\N
405	113	4642	\N	199.00	Opened	\N	\N	\N	f	\N
406	114	4533	\N	0.00	Opened	\N	\N	\N	f	\N
407	115	4453	\N	0.00	Opened	\N	\N	\N	f	\N
408	116	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
409	117	\N	\N	143.20	Opened	Changed	Tino	\N	f	\N
410	118	4532	\N	169.00	Opened	\N	\N	\N	f	\N
411	119	4531	\N	0.00	Opened	\N	\N	\N	f	\N
412	120	4657	\N	199.00	Opened	\N	\N	\N	f	\N
413	121	4311	\N	0.00	Opened	\N	\N	\N	f	\N
414	122	4614	\N	199.00	Opened	\N	\N	\N	f	\N
415	123	4628	\N	169.00	Opened	\N	\N	\N	f	\N
416	124	4510	\N	0.00	Opened	\N	\N	\N	f	\N
417	125	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
418	126	4533	\N	169.00	Opened	\N	\N	\N	f	\N
419	127	4530	\N	0.00	Opened	\N	\N	\N	f	\N
420	128	4560	\N	143.20	Opened	Changed	Tino	\N	f	\N
421	129	4642	\N	199.00	Opened	\N	\N	\N	f	\N
423	129	4642	\N	199.00	Opened	\N	\N	\N	f	\N
424	132	4532	\N	169.00	Opened	\N	\N	\N	f	\N
425	133	4531	\N	0.00	Opened	\N	\N	\N	f	\N
426	134	4557	\N	0.00	Opened	\N	\N	\N	f	\N
427	135	4657	\N	199.00	Opened	\N	\N	\N	f	\N
429	137	4623	\N	169.00	Opened	\N	\N	\N	f	\N
430	138	4469	\N	0.00	Opened	\N	\N	\N	f	\N
431	139	4453	\N	0.00	Opened	\N	\N	\N	f	\N
432	140	4610	\N	199.00	Opened	\N	\N	\N	f	\N
433	141	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
434	146	3251	\N	129.00	closed	Changed	Julia	Tino	t	All Good
435	145	4642	\N	199.00	Opened	\N	\N	\N	f	\N
436	148	4410	\N	149.00	Opened	Changed	Julia	Tino	t	All Good
437	149	4410	\N	149.00	Opened	Changed	Julia	Tino	t	All Good
438	150	4311	\N	0.00	Opened	\N	\N	\N	f	\N
439	151	4628	\N	169.00	Opened	\N	\N	\N	f	\N
440	152	4510	\N	0.00	Opened	\N	\N	\N	f	\N
441	153	4453	\N	0.00	Opened	\N	\N	\N	f	\N
442	154	4614	\N	199.00	Opened	\N	\N	\N	f	\N
443	155	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
444	156	4533	\N	169.00	Opened	\N	\N	\N	f	\N
445	157	4530	\N	0.00	Opened	\N	\N	\N	f	\N
446	158	4560	\N	143.20	Opened	Changed	Tino	\N	f	\N
447	159	4642	\N	199.00	Opened	\N	\N	\N	f	\N
449	159	4642	\N	199.00	Opened	\N	\N	\N	f	\N
450	162	4469	\N	0.00	Opened	\N	\N	\N	f	\N
451	163	4619	\N	169.00	Opened	\N	\N	\N	f	\N
452	168	4453	\N	0.00	Opened	\N	\N	\N	f	\N
453	165	4604	\N	199.00	Opened	\N	\N	\N	f	\N
454	165	4604	\N	199.00	Opened	\N	\N	\N	f	\N
455	167	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
456	168	4453	\N	0.00	Opened	\N	\N	\N	f	\N
457	169	4532	\N	169.00	Opened	\N	\N	\N	f	\N
458	172	4657	\N	199.00	Opened	\N	\N	\N	f	\N
460	174	4532	\N	169.00	Opened	\N	\N	\N	f	\N
461	175	4531	\N	0.00	Opened	\N	\N	\N	f	\N
462	176	4557	\N	0.00	Opened	\N	\N	\N	f	\N
463	177	4657	\N	199.00	Opened	\N	\N	\N	f	\N
465	179	4533	\N	169.00	Opened	\N	\N	\N	f	\N
466	180	4530	\N	0.00	Opened	\N	\N	\N	f	\N
467	181	4560	\N	143.20	Opened	Changed	Tino	\N	f	\N
468	182	4642	\N	199.00	Opened	\N	\N	\N	f	\N
470	182	4642	\N	199.00	Opened	\N	\N	\N	f	\N
471	185	4485	\N	169.00	Opened	\N	\N	\N	f	\N
472	186	4476	\N	0.00	Opened	\N	\N	\N	f	\N
473	187	4558	\N	0.00	Opened	\N	\N	\N	f	\N
474	188	4562	\N	199.00	Opened	\N	\N	\N	f	\N
475	189	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
476	190	1895	\N	0.00	Opened	\N	\N	\N	f	\N
477	191	4469	\N	0.00	Opened	\N	\N	\N	f	\N
478	192	4453	\N	0.00	Opened	\N	\N	\N	f	\N
479	193	4563	\N	143.20	Opened	Changed	Tino	\N	f	\N
480	194	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
481	195	4628	\N	169.00	Opened	\N	\N	\N	f	\N
482	196	4510	\N	0.00	Opened	\N	\N	\N	f	\N
483	197	4453	\N	0.00	Opened	\N	\N	\N	f	\N
484	198	4614	\N	199.00	Opened	\N	\N	\N	f	\N
485	199	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
486	200	4410	\N	149.00	Opened	Changed	Julia	Tino	t	All Good
487	200	4410	\N	149.00	closed	Changed	Julia	Tino	t	All Good
488	202	4530	\N	0.00	Opened	\N	\N	\N	f	\N
489	203	4560	\N	143.20	Opened	Changed	Tino	\N	f	\N
490	204	4642	\N	199.00	Opened	\N	\N	\N	f	\N
491	205	3251	\N	129.00	closed	Changed	Julia	Tino	t	All Good
492	204	4642	\N	199.00	Opened	\N	\N	\N	f	\N
493	207	4311	\N	0.00	Opened	\N	\N	\N	f	\N
494	208	4533	\N	169.00	Opened	\N	\N	\N	f	\N
495	209	4530	\N	0.00	Opened	\N	\N	\N	f	\N
496	210	4560	\N	143.20	Opened	Changed	Tino	\N	f	\N
497	211	4642	\N	199.00	Opened	\N	\N	\N	f	\N
499	211	4642	\N	199.00	Opened	\N	\N	\N	f	\N
500	214	4619	\N	169.00	Opened	\N	\N	\N	f	\N
501	215	4469	\N	0.00	Opened	\N	\N	\N	f	\N
502	216	4453	\N	0.00	Opened	\N	\N	\N	f	\N
503	217	4604	\N	199.00	Opened	\N	\N	\N	f	\N
504	218	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
505	220	4629	\N	169.00	Opened	\N	\N	\N	f	\N
506	221	4469	\N	0.00	Opened	\N	\N	\N	f	\N
507	222	4453	\N	0.00	Opened	\N	\N	\N	f	\N
508	223	4608	\N	199.00	Opened	\N	\N	\N	f	\N
509	224	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
510	225	4619	\N	169.00	Opened	\N	\N	\N	f	\N
511	226	4469	\N	0.00	Opened	\N	\N	\N	f	\N
512	227	4453	\N	0.00	Opened	\N	\N	\N	f	\N
513	228	4604	\N	199.00	Opened	\N	\N	\N	f	\N
514	229	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
515	230	4630	\N	169.00	Opened	\N	\N	\N	f	\N
516	231	4469	\N	0.00	Opened	\N	\N	\N	f	\N
517	233	4605	\N	199.00	Opened	\N	\N	\N	f	\N
518	234	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
519	235	4618	\N	169.00	Opened	\N	\N	\N	f	\N
520	236	4469	\N	0.00	Opened	\N	\N	\N	f	\N
521	237	4453	\N	0.00	Opened	\N	\N	\N	f	\N
522	238	4601	\N	199.00	Opened	\N	\N	\N	f	\N
523	239	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
524	240	4618	\N	0.00	Opened	\N	\N	\N	f	\N
525	241	4619	\N	169.00	Opened	\N	\N	\N	f	\N
526	242	4469	\N	0.00	Opened	\N	\N	\N	f	\N
527	243	4453	\N	0.00	Opened	\N	\N	\N	f	\N
528	244	4604	\N	199.00	Opened	\N	\N	\N	f	\N
529	245	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
530	246	4311	\N	0.00	Opened	\N	\N	\N	f	\N
531	247	4410	\N	149.00	closed	\N	\N	Tino	f	Clarification Needed
532	248	4311	\N	0.00	Opened	\N	\N	\N	f	\N
533	249	4453	\N	0.00	Opened	\N	\N	\N	f	\N
534	250	4619	\N	169.00	Opened	\N	\N	\N	f	\N
535	251	4469	\N	0.00	Opened	\N	\N	\N	f	\N
536	252	4604	\N	199.00	Opened	\N	\N	\N	f	\N
537	253	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
538	254	4620	\N	169.00	Opened	\N	\N	\N	f	\N
539	255	4469	\N	0.00	Opened	\N	\N	\N	f	\N
540	256	4453	\N	0.00	Opened	\N	\N	\N	f	\N
541	257	4528	\N	199.00	Opened	\N	\N	\N	f	\N
542	258	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
543	259	4630	\N	169.00	Opened	\N	\N	\N	f	\N
544	260	4469	\N	0.00	Opened	\N	\N	\N	f	\N
545	261	4453	\N	0.00	Opened	\N	\N	\N	f	\N
546	262	4605	\N	199.00	Opened	\N	\N	\N	f	\N
547	263	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
548	264	4311	\N	0.00	Opened	\N	\N	\N	f	\N
549	265	4618	\N	169.00	Opened	Changed	Julia	Tino	t	All Good
550	266	4469	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
551	267	4453	\N	159.00	Opened	Changed	Julia	Tino	t	All Good
552	268	4601	\N	179.00	Opened	Changed	Julia	Tino	t	All Good
553	269	3251	\N	129.00	Opened	Changed	Tino	Tino	t	All Good
554	270	4618	\N	169.00	Opened	\N	\N	\N	f	\N
555	271	4469	\N	0.00	Opened	\N	\N	\N	f	\N
556	272	4453	\N	0.00	Opened	\N	\N	\N	f	\N
557	273	4601	\N	199.00	Opened	\N	\N	\N	f	\N
558	274	3251	\N	129.00	Opened	Changed	Tino	Julia	t	All Good
559	275	1895	\N	0.00	Opened	\N	\N	\N	f	\N
560	276	4469	\N	0.00	Opened	\N	\N	\N	f	\N
561	277	4453	\N	0.00	Opened	\N	\N	\N	f	\N
562	278	4525	\N	143.20	Opened	Changed	Tino	\N	f	\N
563	279	3251	\N	129.00	Opened	Changed	Tino	Julia	t	All Good
564	280	4311	\N	0.00	Opened	\N	\N	\N	f	\N
565	281	1895	\N	0.00	Opened	\N	\N	\N	f	\N
566	282	4469	\N	0.00	Opened	\N	\N	\N	f	\N
567	283	4453	\N	0.00	Opened	\N	\N	\N	f	\N
568	284	4525	\N	143.20	Opened	Changed	Tino	\N	f	\N
569	285	3251	\N	129.00	Opened	Changed	Tino	Julia	t	All Good
570	92	4628	\N	0.00	Opened	\N	\N	\N	t	\N
571	93	4510	\N	0.00	Opened	\N	\N	\N	t	\N
572	94	4453	\N	0.00	Opened	\N	\N	\N	t	\N
573	95	4606	\N	0.00	Opened	\N	\N	\N	t	\N
574	96	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
575	1	4634	37	152.00	Opened	Changed	Tino	Tino	t	All Good
576	2	4475	47	116.00	Opened	Error	Tino	Tino	f	Pending
577	3	\N	68	199.50	Opened	Changed	Julia	\N	f	\N
578	4	4533	13	152.00	Opened	\N	\N	\N	f	\N
579	5	4478	41	116.00	Opened	\N	\N	\N	f	\N
580	6	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
581	7	\N	68	199.50	Opened	Changed	Julia	\N	f	\N
582	8	3251	86	129.50	Done	OK	Julia	Tino	t	All Good
583	10	4653	106	143.00	Opened	\N	\N	\N	f	\N
584	11	4532	8	152.00	Opened	OK	Tino	\N	f	\N
585	12	4531	40	116.00	Opened	OK	Tino	\N	f	\N
586	13	4657	60	179.00	Opened	Changed	Julia	\N	f	\N
587	14	3251	86	129.50	Cancelled	OK	Tino	Tino	t	All Good
588	15	4533	13	152.00	Opened	\N	\N	\N	f	\N
589	16	4478	41	116.00	Opened	\N	\N	\N	f	\N
590	17	4556	98	143.00	Opened	\N	\N	\N	f	\N
591	18	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
592	19	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
593	18	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
594	21	4617	7	152.00	Opened	\N	\N	\N	f	\N
595	22	4475	47	116.00	Opened	\N	\N	\N	f	\N
596	23	4653	106	143.00	Opened	\N	\N	\N	f	\N
597	24	4602	64	179.00	Opened	Changed	Julia	\N	f	\N
598	25	3251	86	129.50	closed	Changed	Julia	Tino	t	All Good
599	26	4410	108	149.80	Rescheduled	Changed	Tino	Tino	t	All Good
600	27	4410	108	149.80	Cancelled	Changed	Julia	Tino	t	All Good
601	28	4532	8	152.00	Opened	\N	\N	\N	f	\N
602	29	4531	40	116.00	Opened	\N	\N	\N	f	\N
603	30	4557	97	143.00	Opened	\N	\N	\N	f	\N
604	31	4657	60	179.00	Opened	Changed	Julia	\N	f	\N
605	32	3251	86	129.50	Cancelled	OK	Julia	Tino	t	All Good
606	33	4618	14	152.00	Opened	\N	\N	\N	f	\N
607	34	4475	47	116.00	Opened	\N	\N	\N	f	\N
608	35	4653	106	143.00	Opened	\N	\N	\N	f	\N
609	36	4601	65	179.00	Opened	Changed	Julia	\N	f	\N
610	37	3251	86	129.50	Cancelled	OK	Julia	Tino	t	All Good
611	38	4311	75	134.00	Opened	\N	\N	\N	f	\N
612	39	4533	13	152.00	Opened	\N	\N	\N	f	\N
613	40	4478	41	116.00	Opened	\N	\N	\N	f	\N
614	41	4556	98	143.00	Opened	\N	\N	\N	f	\N
615	42	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
616	43	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
617	42	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
618	45	4532	8	152.00	Opened	\N	\N	\N	f	\N
619	46	4531	40	116.00	Opened	\N	\N	\N	f	\N
620	47	4557	97	143.00	Opened	\N	\N	\N	f	\N
621	48	4657	60	179.00	Opened	Changed	Julia	\N	f	\N
622	49	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
623	50	4533	13	152.00	Opened	\N	\N	\N	f	\N
624	51	4478	41	116.00	Opened	\N	\N	\N	f	\N
625	52	4556	98	143.00	Opened	\N	\N	\N	f	\N
626	53	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
627	54	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
628	53	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
629	56	4634	37	152.00	Opened	\N	\N	\N	f	\N
630	57	4475	47	116.00	Opened	\N	\N	\N	f	\N
631	58	\N	68	179.00	Opened	Changed	Julia	\N	f	\N
632	59	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
633	60	4311	75	134.00	Opened	\N	\N	\N	f	\N
634	61	4311	75	134.00	Opened	\N	\N	\N	f	\N
635	62	4619	15	152.00	Opened	\N	\N	\N	f	\N
636	63	4475	47	116.00	Opened	\N	\N	\N	f	\N
637	64	4653	106	143.00	Opened	\N	\N	\N	f	\N
638	65	4604	50	179.00	Opened	Changed	Julia	\N	f	\N
639	66	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
640	67	4533	13	152.00	Opened	\N	\N	\N	f	\N
641	68	4478	41	116.00	Opened	\N	\N	\N	f	\N
642	69	4556	98	143.00	Opened	\N	\N	\N	f	\N
643	70	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
644	71	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
645	70	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
646	73	4528	72	179.00	Opened	Changed	Julia	\N	f	\N
647	74	4620	9	152.00	Opened	\N	\N	\N	f	\N
648	75	4475	47	116.00	Opened	\N	\N	\N	f	\N
649	76	4619	15	152.00	Opened	\N	\N	\N	f	\N
650	77	4475	47	116.00	Opened	\N	\N	\N	f	\N
651	78	4653	106	143.00	Opened	\N	\N	\N	f	\N
652	79	4604	50	179.00	Opened	Changed	Julia	\N	f	\N
653	80	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
654	81	4533	13	152.00	Opened	\N	\N	\N	f	\N
655	82	4478	41	116.00	Opened	\N	\N	\N	f	\N
656	83	4556	98	143.00	Opened	\N	\N	\N	f	\N
657	84	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
658	85	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
659	84	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
660	87	4532	8	152.00	Opened	\N	\N	\N	f	\N
661	88	4531	40	116.00	Opened	\N	\N	\N	f	\N
662	89	4557	97	143.00	Opened	\N	\N	\N	f	\N
663	90	4657	60	179.00	Opened	Changed	Julia	\N	f	\N
664	91	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
665	92	4628	1	152.00	Opened	\N	\N	\N	f	\N
666	93	4510	43	116.00	Opened	\N	\N	\N	f	\N
667	94	4653	106	143.00	Opened	\N	\N	\N	f	\N
668	95	4614	48	179.00	Opened	Changed	Julia	\N	f	\N
669	96	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
670	97	4621	17	152.00	Opened	\N	\N	\N	f	\N
671	98	4475	47	116.00	Opened	\N	\N	\N	f	\N
672	99	4653	106	143.00	Opened	\N	\N	\N	f	\N
781	209	4478	41	116.00	Opened	\N	\N	\N	f	\N
673	100	4607	52	179.00	Opened	Changed	Julia	\N	f	\N
674	101	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
675	102	4311	75	134.00	Opened	\N	\N	\N	f	\N
676	103	4410	108	149.80	Opened	Changed	Julia	Tino	t	All Good
677	104	4622	2	152.00	Opened	\N	\N	\N	f	\N
678	105	4475	47	116.00	Opened	\N	\N	\N	f	\N
679	106	4653	106	143.00	Opened	\N	\N	\N	f	\N
680	107	4609	53	179.00	Opened	Changed	Julia	\N	f	\N
681	108	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
682	109	4311	75	134.00	Opened	\N	\N	\N	f	\N
683	109	4311	75	134.00	Opened	\N	\N	\N	f	\N
684	111	4533	13	152.00	Opened	\N	\N	\N	f	\N
685	112	4478	41	116.00	Opened	\N	\N	\N	f	\N
686	113	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
687	115	4653	106	143.00	Opened	\N	\N	\N	f	\N
688	116	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
689	117	\N	68	179.00	Opened	Changed	Julia	\N	f	\N
690	118	4532	8	152.00	Opened	\N	\N	\N	f	\N
691	119	4531	40	116.00	Opened	\N	\N	\N	f	\N
692	120	4657	60	179.00	Opened	Changed	Julia	\N	f	\N
693	121	4311	75	134.00	Opened	\N	\N	\N	f	\N
694	122	4614	48	179.00	Opened	Changed	Julia	\N	f	\N
695	123	4628	1	152.00	Opened	\N	\N	\N	f	\N
696	124	4510	43	116.00	Opened	\N	\N	\N	f	\N
697	125	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
698	126	4533	13	152.00	Opened	\N	\N	\N	f	\N
699	127	4478	41	116.00	Opened	\N	\N	\N	f	\N
700	128	4556	98	143.00	Opened	\N	\N	\N	f	\N
701	129	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
702	130	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
703	129	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
704	132	4532	8	152.00	Opened	\N	\N	\N	f	\N
705	133	4531	40	116.00	Opened	\N	\N	\N	f	\N
706	134	4557	97	143.00	Opened	\N	\N	\N	f	\N
707	135	4657	60	179.00	Opened	Changed	Julia	\N	f	\N
708	136	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
709	137	4623	3	152.00	Opened	\N	\N	\N	f	\N
710	138	4475	47	116.00	Opened	\N	\N	\N	f	\N
711	139	4653	106	143.00	Opened	\N	\N	\N	f	\N
712	140	4610	54	179.00	Opened	Changed	Julia	\N	f	\N
713	141	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
714	142	4533	13	152.00	Opened	\N	\N	\N	f	\N
715	143	4478	41	116.00	Opened	\N	\N	\N	f	\N
716	144	4556	98	143.00	Opened	\N	\N	\N	f	\N
717	145	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
718	146	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
719	145	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
720	148	4410	108	149.80	Opened	Changed	Julia	Tino	t	All Good
721	149	4410	108	149.80	Opened	Changed	Julia	Tino	t	All Good
722	150	4311	75	134.00	Opened	\N	\N	\N	f	\N
723	151	4628	1	152.00	Opened	\N	\N	\N	f	\N
724	152	4510	43	116.00	Opened	\N	\N	\N	f	\N
725	153	4653	106	143.00	Opened	\N	\N	\N	f	\N
726	154	4614	48	179.00	Opened	Changed	Julia	\N	f	\N
727	155	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
728	156	4533	13	152.00	Opened	\N	\N	\N	f	\N
729	157	4478	41	116.00	Opened	\N	\N	\N	f	\N
730	158	4556	98	143.00	Opened	\N	\N	\N	f	\N
731	159	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
732	160	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
733	159	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
734	162	4475	47	116.00	Opened	\N	\N	\N	f	\N
735	163	4619	15	152.00	Opened	\N	\N	\N	f	\N
736	168	4653	106	143.00	Opened	\N	\N	\N	f	\N
737	165	4604	50	179.00	Opened	Changed	Julia	\N	f	\N
738	165	4604	50	179.00	Opened	Changed	Julia	\N	f	\N
739	167	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
740	168	4653	106	143.00	Opened	\N	\N	\N	f	\N
741	169	4532	8	152.00	Opened	\N	\N	\N	f	\N
742	170	4531	40	116.00	Opened	\N	\N	\N	f	\N
743	171	4557	97	143.00	Opened	\N	\N	\N	f	\N
744	172	4657	60	179.00	Opened	Changed	Julia	\N	f	\N
745	173	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
746	174	4532	8	152.00	Opened	\N	\N	\N	f	\N
747	175	4531	40	116.00	Opened	\N	\N	\N	f	\N
748	176	4557	97	143.00	Opened	\N	\N	\N	f	\N
749	177	4657	60	179.00	Opened	Changed	Julia	\N	f	\N
750	178	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
751	179	4533	13	152.00	Opened	\N	\N	\N	f	\N
752	180	4478	41	116.00	Opened	\N	\N	\N	f	\N
753	181	4556	98	143.00	Opened	\N	\N	\N	f	\N
754	182	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
755	183	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
756	182	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
757	185	4485	6	152.00	Opened	\N	\N	\N	f	\N
758	186	4476	42	116.00	Opened	\N	\N	\N	f	\N
759	187	4558	96	143.00	Opened	\N	\N	\N	f	\N
760	188	4562	62	179.00	Opened	Changed	Julia	\N	f	\N
761	189	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
762	190	4634	37	152.00	Opened	\N	\N	\N	f	\N
763	191	4475	47	116.00	Opened	\N	\N	\N	f	\N
764	192	4653	106	143.00	Opened	\N	\N	\N	f	\N
765	193	\N	68	179.00	Opened	Changed	Julia	\N	f	\N
766	194	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
767	195	4628	1	152.00	Opened	\N	\N	\N	f	\N
768	196	4510	43	116.00	Opened	\N	\N	\N	f	\N
769	197	4653	106	143.00	Opened	\N	\N	\N	f	\N
770	198	4614	48	179.00	Opened	Changed	Julia	\N	f	\N
771	199	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
772	200	4410	108	149.80	Opened	Changed	Julia	Tino	t	All Good
773	201	4533	13	152.00	Opened	\N	\N	\N	f	\N
774	202	4478	41	116.00	Opened	\N	\N	\N	f	\N
775	203	4556	98	143.00	Opened	\N	\N	\N	f	\N
776	204	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
777	205	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
778	204	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
779	207	4311	75	134.00	Opened	\N	\N	\N	f	\N
780	208	4533	13	152.00	Opened	\N	\N	\N	f	\N
782	210	4556	98	143.00	Opened	\N	\N	\N	f	\N
783	211	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
784	212	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
785	211	4642	59	199.50	Opened	Changed	Julia	\N	f	\N
786	214	4619	15	152.00	Opened	\N	\N	\N	f	\N
787	215	4475	47	116.00	Opened	\N	\N	\N	f	\N
788	216	4653	106	143.00	Opened	\N	\N	\N	f	\N
789	217	4604	50	179.00	Opened	Changed	Julia	\N	f	\N
790	218	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
791	219	4410	108	149.80	Opened	Changed	Julia	Tino	t	All Good
792	220	4629	18	152.00	Opened	\N	\N	\N	f	\N
793	221	4475	47	116.00	Opened	\N	\N	\N	f	\N
794	222	4653	106	143.00	Opened	\N	\N	\N	f	\N
795	223	4608	55	179.00	Opened	Changed	Julia	\N	f	\N
796	224	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
797	225	4619	15	152.00	Opened	\N	\N	\N	f	\N
798	226	4475	47	116.00	Opened	\N	\N	\N	f	\N
799	227	4653	106	143.00	Opened	\N	\N	\N	f	\N
800	228	4604	50	179.00	Opened	Changed	Julia	\N	f	\N
801	229	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
802	230	4630	4	152.00	Opened	\N	\N	\N	f	\N
803	231	4475	47	116.00	Opened	\N	\N	\N	f	\N
804	232	4653	106	143.00	Opened	\N	\N	\N	f	\N
805	233	4605	56	179.00	Opened	Changed	Julia	\N	f	\N
806	234	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
807	235	4618	14	152.00	Opened	\N	\N	\N	f	\N
808	236	4475	47	116.00	Opened	\N	\N	\N	f	\N
809	237	4653	106	143.00	Opened	\N	\N	\N	f	\N
810	238	4601	65	179.00	Opened	Changed	Julia	\N	f	\N
811	239	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
812	241	4619	15	152.00	Opened	\N	\N	\N	f	\N
813	242	4475	47	116.00	Opened	\N	\N	\N	f	\N
814	243	4653	106	143.00	Opened	\N	\N	\N	f	\N
815	244	4604	50	179.00	Opened	Changed	Julia	\N	f	\N
816	245	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
817	246	4311	75	134.00	Opened	\N	\N	\N	f	\N
818	247	4410	108	149.80	Opened	Changed	Julia	Tino	t	All Good
819	248	4311	75	134.00	Opened	\N	\N	\N	f	\N
820	249	4653	106	143.00	Opened	\N	\N	\N	f	\N
821	250	4619	15	152.00	Opened	\N	\N	\N	f	\N
822	251	4475	47	116.00	Opened	\N	\N	\N	f	\N
823	252	4604	50	179.00	Opened	Changed	Julia	\N	f	\N
824	253	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
825	254	4620	9	152.00	Opened	\N	\N	\N	f	\N
826	255	4475	47	116.00	Opened	\N	\N	\N	f	\N
827	256	4653	106	143.00	Opened	\N	\N	\N	f	\N
828	257	4528	72	179.00	Opened	Changed	Julia	\N	f	\N
829	258	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
830	259	4630	4	152.00	Opened	\N	\N	\N	f	\N
831	260	4475	47	116.00	Opened	\N	\N	\N	f	\N
832	261	4653	106	143.00	Opened	\N	\N	\N	f	\N
833	262	4605	56	179.00	Opened	Changed	Julia	\N	f	\N
834	263	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
835	264	4311	75	134.00	Opened	\N	\N	\N	f	\N
836	265	4618	14	169.00	Opened	Changed	Julia	Tino	t	All Good
837	266	4475	47	129.00	Opened	Changed	Julia	Tino	t	All Good
838	267	4653	106	159.00	Opened	Changed	Julia	Tino	t	All Good
839	268	4601	65	179.00	Opened	Changed	Julia	Tino	t	All Good
840	269	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
841	270	4618	14	152.00	Opened	\N	\N	\N	f	\N
842	271	4475	47	116.00	Opened	\N	\N	\N	f	\N
843	272	4653	106	143.00	Opened	\N	\N	\N	f	\N
844	273	4601	65	179.00	Opened	Changed	Julia	\N	f	\N
845	274	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
846	275	4634	37	152.00	Opened	\N	\N	\N	f	\N
847	276	4475	47	116.00	Opened	\N	\N	\N	f	\N
848	277	4653	106	143.00	Opened	\N	\N	\N	f	\N
849	278	\N	68	179.00	Opened	Changed	Julia	\N	f	\N
850	279	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
851	280	4311	75	134.00	Opened	\N	\N	\N	f	\N
852	281	4634	37	152.00	Opened	\N	\N	\N	f	\N
853	282	4475	47	116.00	Opened	\N	\N	\N	f	\N
854	283	4653	106	143.00	Opened	\N	\N	\N	f	\N
855	284	\N	68	179.00	Opened	Changed	Julia	\N	f	\N
856	285	3251	86	129.50	Opened	OK	Julia	Tino	t	All Good
857	92	4628	1	0.00	Opened	\N	\N	\N	t	\N
858	93	4510	43	0.00	Opened	\N	\N	\N	t	\N
859	94	4453	95	0.00	Opened	\N	\N	\N	t	\N
860	95	4606	51	0.00	Opened	\N	\N	\N	t	\N
861	96	4693	80	129.50	Opened	OK	Julia	Tino	t	All Good
862	164	4604	\N	\N	Opened	\N	\N	\N	f	\N
863	164	4453	\N	\N	Opened	\N	\N	\N	f	\N
864	7	\N	\N	\N	Opened	Changed	Tino	\N	f	\N
14	14	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
19	19	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
49	49	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
54	54	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
85	85	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
91	91	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
103	103	4410	\N	134.00	closed	edited	Julia	Tino	t	All Good
130	130	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
136	136	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
160	160	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
173	173	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
178	178	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
183	183	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
212	212	3251	\N	129.50	closed	edited	Julia	Tino	t	All Good
304	14	3251	\N	129.00	Cancelled	Changed	Julia	Tino	t	All Good
309	19	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
339	49	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
344	54	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
376	85	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
382	91	3251	\N	129.00	Opened	Changed	Tino	Tino	t	All Good
395	103	4410	\N	149.00	Opened	Changed	Max	Tino	t	All Good
422	130	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
428	136	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
448	160	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
865	164	4653	106	\N	Opened	\N	\N	\N	f	\N
459	173	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
464	178	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
469	183	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
498	212	3251	\N	129.00	Opened	Changed	Julia	Tino	t	All Good
\.


--
-- Data for Name: ship; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ship (ship_id, name) FROM stdin;
1	Sky Princess
2	Oceania Insignia
3	Carnival Legend
4	Celebrity Apex
5	Oceana Sirena
6	Crown Princess
7	Norwegian Sun
8	Liberty of the Seas
9	Norwegian Star
10	Sapphire Princess
11	Majestic Princess
12	Norwegian Sky
13	Celebrity Eclipse
14	Nieuw Statendam
15	MS Nieuw Statendam
16	Combine tour
17	MSC Virtuosa
18	Oceana Marina
19	Oceania Cruises
20	Voyagens
21	Oceania Vista
\.


--
-- Data for Name: ship_docking; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ship_docking (docking_id, ship_id, port_id, date, dock_start, dock_end) FROM stdin;
1	15	1	2026-04-16	07:00:00	19:00:00
2	11	1	2026-04-16	07:00:00	20:00:00
3	16	1	2026-04-16	07:00:00	19:00:00
4	12	1	2026-04-19	05:30:00	19:00:00
5	11	1	2026-04-27	07:00:00	20:00:00
6	10	1	2026-04-28	07:00:00	20:00:00
7	9	2	2026-05-01	06:30:00	21:00:00
8	9	2	2026-05-02	07:00:00	21:00:00
9	12	1	2026-05-03	05:30:00	19:00:00
10	9	1	2026-05-04	06:30:00	21:00:00
11	17	3	2026-05-07	09:00:00	19:00:00
12	11	1	2026-05-09	07:00:00	20:00:00
13	12	1	2026-05-18	06:30:00	21:00:00
14	11	1	2026-05-21	07:00:00	20:00:00
15	18	1	2026-05-24	08:00:00	17:00:00
16	18	3	2026-05-25	07:00:00	17:00:00
17	17	3	2026-05-26	07:00:00	19:00:00
18	8	1	2026-05-30	07:00:00	21:00:00
19	11	1	2026-06-02	07:00:00	20:00:00
20	16	1	2026-06-02	\N	\N
21	7	1	2026-06-02	06:00:00	19:00:00
22	8	1	2026-06-13	07:00:00	21:00:00
23	11	1	2026-06-14	07:00:00	20:00:00
24	12	1	2026-06-17	06:30:00	21:00:00
25	3	1	2026-06-20	07:00:00	19:00:00
26	6	1	2026-06-21	07:00:00	20:00:00
27	17	3	2026-06-26	07:00:00	19:00:00
28	19	2	2026-06-27	07:00:00	18:00:00
29	5	1	2026-07-01	07:00:00	19:00:00
30	17	3	2026-07-03	08:00:00	20:00:00
31	11	1	2026-07-08	07:00:00	20:00:00
32	16	1	2026-07-08	\N	\N
33	12	1	2026-07-08	06:30:00	21:00:00
34	17	3	2026-07-10	07:00:00	19:00:00
35	3	1	2026-07-18	07:00:00	18:00:00
36	11	1	2026-07-20	07:00:00	20:00:00
37	12	1	2026-07-29	06:30:00	21:00:00
38	4	1	2026-07-31	07:00:00	22:00:00
39	11	1	2026-08-01	07:00:00	20:00:00
40	20	2	2026-08-03	08:30:00	20:00:00
41	19	2	2026-08-07	07:00:00	19:00:00
42	1	3	2026-08-09	07:00:00	18:00:00
43	3	1	2026-08-10	07:00:00	20:00:00
44	11	1	2026-08-13	07:00:00	20:00:00
45	8	1	2026-08-15	08:00:00	21:00:00
46	12	1	2026-08-19	06:30:00	21:00:00
47	12	1	2026-08-23	06:30:00	19:00:00
48	11	1	2026-08-25	07:00:00	20:00:00
49	13	1	2026-08-28	07:00:00	20:00:00
50	21	1	2026-08-28	\N	\N
51	3	1	2026-08-31	07:00:00	20:00:00
52	3	2	2026-09-02	08:00:00	17:00:00
53	11	1	2026-09-06	07:00:00	20:00:00
54	17	3	2026-09-11	07:00:00	19:00:00
55	11	1	2026-09-18	07:00:00	20:00:00
56	8	1	2026-09-19	07:00:00	20:00:00
57	18	2	2026-09-19	\N	\N
58	2	1	2026-09-21	\N	\N
59	8	1	2026-09-26	07:00:00	20:00:00
60	1	1	2026-09-27	07:00:00	20:00:00
61	9	1	2026-09-30	08:00:00	21:00:00
62	8	1	2026-10-02	08:00:00	21:00:00
63	9	2	2026-10-03	07:00:00	18:00:00
64	8	3	2026-10-04	07:00:00	18:00:00
65	8	1	2026-10-09	08:00:00	22:00:00
66	7	1	2026-10-13	06:00:00	19:00:00
67	1	1	2026-11-04	07:00:00	20:00:00
68	1	3	2026-11-06	07:00:00	16:00:00
69	9	1	2026-11-19	07:00:00	21:30:00
70	9	1	2026-11-21	06:00:00	19:00:00
71	15	1	2026-12-07	08:00:00	21:00:00
72	15	3	2026-12-08	07:00:00	19:00:00
73	15	1	2026-12-09	08:00:00	21:00:00
\.


--
-- Data for Name: shore_excursion; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shore_excursion (shorex_id, name, primary_port_id) FROM stdin;
1	Paris Shared	1
2	POYO	1
3	D-DAY	1
4	D-day from Cherbourg	3
5	HnD	1
6	MSM	1
7	Le Verdon - Bordeaux - shared tour	2
8	Bordoyo - transferon your own	2
9	Rouen shared	1
\.


--
-- Data for Name: tour; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tour (tour_id, shorex_id, name, status, link) FROM stdin;
1345	3	Normandy D-Day Beaches Shore Excursion with Packed Lunch from Le Havre Cruise Port	Published	https://www.vexperio.com/nova/resources/tour-options/1865
1375	2	From Le Havre Port: Round-Trip Transfer to Paris by Bus	Published	https://www.vexperio.com/nova/resources/tour-options/4469
1385	1	From Le Havre: Paris Highlights with Seine River Cruise - the Best Shore Excursion	Published	https://www.vexperio.com/nova/resources/tour-options/1895
1581	4	From Cherbourg: D-Day Beaches Shore Excursion	Published	https://www.vexperio.com/nova/resources/tour-options/4311
1591	5	Seaside Charms: Discover Honfleur and Deauville from Le Havre	Published	https://www.vexperio.com/nova/resources/tour-options/4689
1744	6	Mont Saint Michel Shore Excursion from Le Havre Port	Published	https://www.vexperio.com/nova/resources/tour-options/4453
1745	8	Bordeaux on Your Own: Shore Excursion from Le Verdon for Cruise Passengers	Published	https://www.vexperio.com/nova/resources/tour-options/4404
1747	7	Exclusive Bordeaux Shore Excursion from Le Verdon Cruise Port	Published	https://www.vexperio.com/nova/resources/tour-options/4410
\.


--
-- Data for Name: tour_option; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tour_option (option_id, tour_id, name, is_private, ship_id, base_price, link) FROM stdin;
4634	1385	Shared ShorEX	f	\N	152.00	https://www.vexperio.com/nova/resources/tour-options/4634
4630	1385	Paris Highlights - Sky Princess	f	1	152.00	https://www.vexperio.com/nova/resources/tour-options/4630
4629	1385	Paris Highlights - Oceania Insignia	f	2	152.00	https://www.vexperio.com/nova/resources/tour-options/4629
4628	1385	Paris Highlights - Carnival Legend	f	3	152.00	https://www.vexperio.com/nova/resources/tour-options/4628
4623	1385	Paris Highlights - Celebrity Apex	f	4	152.00	https://www.vexperio.com/nova/resources/tour-options/4623
4622	1385	Paris Highlights - Oceana Sirena	f	5	152.00	https://www.vexperio.com/nova/resources/tour-options/4622
4621	1385	Paris Highlights - Crown Princess	f	6	152.00	https://www.vexperio.com/nova/resources/tour-options/4621
4620	1385	Paris Highlights - Norwegian Sun	f	7	152.00	https://www.vexperio.com/nova/resources/tour-options/4620
4619	1385	Paris Highlights - Liberty of the Seas	f	8	152.00	https://www.vexperio.com/nova/resources/tour-options/4619
4618	1385	Paris Highlights - Norwegian Star	f	9	152.00	https://www.vexperio.com/nova/resources/tour-options/4618
4617	1385	Paris Highlights - Sapphire Princess	f	10	152.00	https://www.vexperio.com/nova/resources/tour-options/4617
4533	1385	Paris Highlights - Majestic Princess	f	11	152.00	https://www.vexperio.com/nova/resources/tour-options/4533
4532	1385	Paris Highlights - Norwegian Sky	f	12	152.00	https://www.vexperio.com/nova/resources/tour-options/4532
4509	1385	Paris Highlights - Carnival Legend 9h tour	f	3	152.00	https://www.vexperio.com/nova/resources/tour-options/4509
4491	1385	Shared Tour Paris Sightseeing	f	\N	152.00	https://www.vexperio.com/nova/resources/tour-options/4491
4486	1385	Paris Highlights - Oceania Vista	f	\N	152.00	https://www.vexperio.com/nova/resources/tour-options/4486
4485	1385	Paris Highlights - Celebrity Eclipse	f	13	152.00	https://www.vexperio.com/nova/resources/tour-options/4485
4482	1385	Paris Highlights - Nieuw Statendam	f	14	152.00	https://www.vexperio.com/nova/resources/tour-options/4482
3401	1385	From Le Havre: Private Guided Day Trip Shore Excursion with Shared Transfer	t	\N	\N	https://www.vexperio.com/nova/resources/tour-options/3401
1895	1385	Private Paris Shore Excursion	t	\N	\N	https://www.vexperio.com/nova/resources/tour-options/1895
4531	1375	2026 July 8th Paris - Norwegian Sky	f	12	116.00	https://www.vexperio.com/nova/resources/tour-options/4531
4530	1375	2026 July 8th Paris - Majestic Princess	f	11	116.00	https://www.vexperio.com/nova/resources/tour-options/4530
4510	1375	2026 July 18th Paris - Carnival Legend	f	3	116.00	https://www.vexperio.com/nova/resources/tour-options/4510
4480	1375	2026 April 16th Paris - Majestic Princess	f	11	116.00	https://www.vexperio.com/nova/resources/tour-options/4480
4479	1375	2026 April 16th Paris - Nieuw Statendam	f	14	116.00	https://www.vexperio.com/nova/resources/tour-options/4479
4478	1375	2026 June 2nd Paris - Majestic Princess	f	11	116.00	https://www.vexperio.com/nova/resources/tour-options/4478
4476	1375	2026 August 28th Paris - Celebrity Eclipse	f	13	116.00	https://www.vexperio.com/nova/resources/tour-options/4476
4475	1375	2026 August 28th Paris - Oceania Vista	f	\N	116.00	https://www.vexperio.com/nova/resources/tour-options/4475
4472	1375	2025 September 15th Paris - Regal Princess	f	\N	116.00	https://www.vexperio.com/nova/resources/tour-options/4472
4471	1375	2025 September 15th Paris - Norwegian Prima	f	\N	116.00	https://www.vexperio.com/nova/resources/tour-options/4471
4470	1375	Shared Tour Paris on Your Own	f	\N	116.00	https://www.vexperio.com/nova/resources/tour-options/4470
4469	1375	Ticket for Paris on Your Own	f	\N	116.00	https://www.vexperio.com/nova/resources/tour-options/4469
4657	1345	Norwegian Sky - 9 hour tour	f	12	179.00	https://www.vexperio.com/nova/resources/tour-options/4657
4656	1345	Norwegian Sky - 10 hour tour	f	12	179.00	https://www.vexperio.com/nova/resources/tour-options/4656
4642	1345	Majestic Princess - 9 hour tour	f	11	179.00	https://www.vexperio.com/nova/resources/tour-options/4642
4641	1345	Nieuw Statendam - 9 hour tour	f	14	179.00	https://www.vexperio.com/nova/resources/tour-options/4641
4614	1345	Carnival Legend - 9 hour tour	f	3	179.00	https://www.vexperio.com/nova/resources/tour-options/4614
4610	1345	Celebrity Apex - 10 hour tour	f	4	179.00	https://www.vexperio.com/nova/resources/tour-options/4610
4609	1345	Oceana Sirena - 10 hour tour	f	5	179.00	https://www.vexperio.com/nova/resources/tour-options/4609
4608	1345	Oceania Insignia - 10 hour tour	f	2	179.00	https://www.vexperio.com/nova/resources/tour-options/4608
4607	1345	Crown Princess - 10 hour tour	f	6	179.00	https://www.vexperio.com/nova/resources/tour-options/4607
4606	1345	Carnival Legend - 10 hour tour	f	3	179.00	https://www.vexperio.com/nova/resources/tour-options/4606
4605	1345	Sky Princess - 10 hour tour	f	1	179.00	https://www.vexperio.com/nova/resources/tour-options/4605
4604	1345	Liberty of the Seas - 10 hour tour	f	8	179.00	https://www.vexperio.com/nova/resources/tour-options/4604
4603	1345	Oceana Marina - 8 hour tour	f	\N	179.00	https://www.vexperio.com/nova/resources/tour-options/4603
4602	1345	Sapphire Princess - 10 hour tour	f	10	179.00	https://www.vexperio.com/nova/resources/tour-options/4602
4601	1345	Norwegian Star - 10 hour tour	f	9	179.00	https://www.vexperio.com/nova/resources/tour-options/4601
4574	1345	Shared ShorEX D-Day 2026	f	\N	179.00	https://www.vexperio.com/nova/resources/tour-options/4574
4563	1345	Oceania Vista - 10 hour tour	f	\N	179.00	https://www.vexperio.com/nova/resources/tour-options/4563
4562	1345	Celebrity Eclipse - 10 hour tour	f	13	179.00	https://www.vexperio.com/nova/resources/tour-options/4562
4561	1345	Norwegian Sky - 10 hour tour	f	12	179.00	https://www.vexperio.com/nova/resources/tour-options/4561
4560	1345	Majestic Princess - 10 hour tour	f	11	179.00	https://www.vexperio.com/nova/resources/tour-options/4560
4559	1345	Shared 8h D-Day Tour From Le Havre Port	f	\N	179.00	https://www.vexperio.com/nova/resources/tour-options/4559
4528	1345	Norwegian Sun - 10 hour tour	f	7	179.00	https://www.vexperio.com/nova/resources/tour-options/4528
4525	1345	Nieuw Statendam - 10 hour tour	f	14	179.00	https://www.vexperio.com/nova/resources/tour-options/4525
4495	1345	Shared D-Day Tour	f	\N	179.00	https://www.vexperio.com/nova/resources/tour-options/4495
4494	1345	Ticket for D-Day Tour	f	\N	179.00	https://www.vexperio.com/nova/resources/tour-options/4494
4493	1345	Shared 9h D-Day Tour From Le Havre Port	f	\N	179.00	https://www.vexperio.com/nova/resources/tour-options/4493
1865	1345	Private Tour of D-Day Beaches Normandy from Le Havre Port	t	\N	\N	https://www.vexperio.com/nova/resources/tour-options/1865
4571	1581	7 Hour Shared Tour	f	\N	134.00	https://www.vexperio.com/nova/resources/tour-options/4571
4321	1581	Private D-Day Tour from the Port of Cherbourg	t	\N	\N	https://www.vexperio.com/nova/resources/tour-options/4321
4311	1581	Shared D-Day Tour from the Port of Cherbourg	f	\N	134.00	https://www.vexperio.com/nova/resources/tour-options/4311
4552	1591	Honfleur and Deauville from Le Havre- Oceania Vista	f	\N	116.00	https://www.vexperio.com/nova/resources/tour-options/4552
4551	1591	Honfleur and Deauville from Le Havre - Celebrity Eclipse	f	13	116.00	https://www.vexperio.com/nova/resources/tour-options/4551
4550	1591	Honfleur and Deauville from Le Havre - Norwegian Sky	f	12	116.00	https://www.vexperio.com/nova/resources/tour-options/4550
4549	1591	Honfleur and Deauville from Le Havre - Majestic Princess	f	11	116.00	https://www.vexperio.com/nova/resources/tour-options/4549
4547	1591	Honfleur and Deauville from Le Havre- Majestic Princess	f	11	116.00	https://www.vexperio.com/nova/resources/tour-options/4547
4452	1591	Private Honfleur and Deauville Tour	t	\N	\N	https://www.vexperio.com/nova/resources/tour-options/4452
3251	1591	Honfleur and Deauville Shared Tour Ticket	f	\N	116.00	https://www.vexperio.com/nova/resources/tour-options/3251
4700	1591	Honfleur and Deauville from Le Havre- Oceania Insignia	f	2	116.00	https://www.vexperio.com/nova/resources/tour-options/4700
4699	1591	Honfleur and Deauville from Le Havre- Sky Princess	f	1	116.00	https://www.vexperio.com/nova/resources/tour-options/4699
4698	1591	Honfleur and Deauville from Le Havre- MS Nieuw Statendam	f	14	116.00	https://www.vexperio.com/nova/resources/tour-options/4698
4697	1591	Honfleur and Deauville from Le Havre- Celebrity Apex	f	4	116.00	https://www.vexperio.com/nova/resources/tour-options/4697
4696	1591	Honfleur and Deauville from Le Havre- Norwegian Star	f	9	116.00	https://www.vexperio.com/nova/resources/tour-options/4696
4695	1591	Honfleur and Deauville from Le Havre - Oceana Sirena	f	5	116.00	https://www.vexperio.com/nova/resources/tour-options/4695
4694	1591	Honfleur and Deauville from Le Havre - Crown Princess	f	6	116.00	https://www.vexperio.com/nova/resources/tour-options/4694
4693	1591	Honfleur and Deauville from Le Havre - Carnival Legend	f	3	116.00	https://www.vexperio.com/nova/resources/tour-options/4693
4692	1591	Honfleur and Deauville from Le Havre- Liberty of the Seas	f	8	116.00	https://www.vexperio.com/nova/resources/tour-options/4692
4691	1591	Honfleur and Deauville from Le Havre- Oceana Marina	f	\N	116.00	https://www.vexperio.com/nova/resources/tour-options/4691
4690	1591	Honfleur and Deauville from Le Havre- Norwegian Sun	f	7	116.00	https://www.vexperio.com/nova/resources/tour-options/4690
4689	1591	Honfleur and Deauville - Sapphire Princess	f	10	116.00	https://www.vexperio.com/nova/resources/tour-options/4689
4653	1744	Mont Saint Michel Shared Tour - 11h	f	\N	143.00	https://www.vexperio.com/nova/resources/tour-options/4653
4644	1744	Mont Saint Michel Only for Majestic Princess	f	11	143.00	https://www.vexperio.com/nova/resources/tour-options/4644
4558	1744	2026 August 28th Mont Saint Michel - ONLY Celebrity Eclipse	f	13	143.00	https://www.vexperio.com/nova/resources/tour-options/4558
4557	1744	2026 July 8th - Mont Saint Michel - Norwegian Sky	f	12	143.00	https://www.vexperio.com/nova/resources/tour-options/4557
4556	1744	2026 July 8th- Mont Saint Michel - Majestic Princess	f	11	143.00	https://www.vexperio.com/nova/resources/tour-options/4556
4453	1744	Mont Saint Michel Shared Tour	f	\N	143.00	https://www.vexperio.com/nova/resources/tour-options/4453
4513	1747	9-Hour Guided Group Tour of Bordeaux from Le Verdon Cruise Port	f	\N	134.00	https://www.vexperio.com/nova/resources/tour-options/4513
4411	1747	7-Hour Guided Group Tour of Bordeaux from Le Verdon Cruise Port	f	\N	134.00	https://www.vexperio.com/nova/resources/tour-options/4411
4410	1747	8-Hour Guided Group Tour of Bordeaux from Le Verdon Cruise Port	f	\N	134.00	https://www.vexperio.com/nova/resources/tour-options/4410
4406	1745	8-Hour Round-Trip with Shared Transfer	f	\N	109.00	https://www.vexperio.com/nova/resources/tour-options/4406
4405	1745	8-Hour Round-Trip Shared Transfer	f	\N	109.00	https://www.vexperio.com/nova/resources/tour-options/4405
4404	1745	7-Hour Round-Trip Shared Transfer	f	\N	109.00	https://www.vexperio.com/nova/resources/tour-options/4404
\.


--
-- Data for Name: tour_schedule; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tour_schedule (schedule_id, docking_id, shorex_id, start_time, tour_type, duration_hours, status) FROM stdin;
1	1	1	07:30:00	Shared	10	confirmed
2	1	2	07:30:00	Shared	10	confirmed
3	1	3	08:00:00	Shared	10	confirmed
4	2	1	07:30:00	Shared	11	confirmed
5	2	2	07:30:00	Shared	11	confirmed
6	2	3	08:30:00	Shared	10	confirmed
7	3	3	09:00:00	Shared	9	confirmed
8	3	5	09:00:00	Shared	6	confirmed
9	3	9	09:00:00	Shared	\N	confirmed
10	3	6	07:30:00	Shared	10	Cancelled
11	4	1	06:30:00	Shared	10	confirmed
12	4	2	06:30:00	Shared	10	confirmed
13	4	3	07:30:00	Shared	10	confirmed
14	4	5	08:30:00	Shared	6	confirmed
15	5	1	07:30:00	Shared	11	confirmed
16	5	2	07:30:00	Shared	11	confirmed
17	5	6	07:30:00	Shared	11	confirmed
18	5	3	08:30:00	Shared	10	confirmed
19	5	5	09:00:00	Shared	6	confirmed
20	5	3	09:30:00	Shared	9	confirmed
21	6	1	07:30:00	Shared	11	confirmed
22	6	2	07:30:00	Shared	11	confirmed
23	6	6	07:30:00	Shared	11	confirmed
24	6	3	08:30:00	Shared	10	confirmed
25	6	5	09:00:00	Shared	6	confirmed
26	7	7	08:00:00	Shared	8	confirmed
27	8	7	08:00:00	Shared	8	confirmed
28	9	1	06:30:00	Shared	11	confirmed
29	9	2	06:30:00	Shared	11	confirmed
30	9	6	06:30:00	Shared	11	confirmed
31	9	3	07:30:00	Shared	10	confirmed
32	9	5	08:30:00	Shared	6	confirmed
33	10	1	07:30:00	Shared	11	confirmed
34	10	2	07:30:00	Shared	11	confirmed
35	10	6	07:30:00	Shared	11	confirmed
36	10	3	08:30:00	Shared	10	confirmed
37	10	5	09:00:00	Shared	6	confirmed
38	11	4	09:30:00	Shared	8	confirmed
39	12	1	07:30:00	Shared	11	confirmed
40	12	2	07:30:00	Shared	11	confirmed
41	12	6	07:30:00	Shared	11	confirmed
42	12	3	08:30:00	Shared	10	confirmed
43	12	5	09:00:00	Shared	6	confirmed
44	12	3	09:30:00	Shared	9	confirmed
45	13	1	07:30:00	Shared	11	confirmed
46	13	2	07:30:00	Shared	11	confirmed
47	13	6	07:30:00	Shared	11	confirmed
48	13	3	08:30:00	Shared	10	confirmed
49	13	5	09:00:00	Shared	6	confirmed
50	14	1	07:30:00	Shared	11	confirmed
51	14	2	07:30:00	Shared	11	confirmed
52	14	6	07:30:00	Shared	11	confirmed
53	14	3	08:30:00	Shared	10	confirmed
54	14	5	09:00:00	Shared	6	confirmed
55	14	3	09:30:00	Shared	9	confirmed
56	15	1	\N	Shared	\N	confirmed
57	15	2	\N	Shared	\N	confirmed
58	15	3	08:30:00	Shared	\N	confirmed
59	15	5	09:00:00	Shared	6	confirmed
60	16	4	07:30:00	Shared	8	confirmed
61	17	4	08:00:00	Shared	8	confirmed
62	18	1	08:00:00	Shared	11	confirmed
63	18	2	08:00:00	Shared	11	confirmed
64	18	6	08:00:00	Shared	11	confirmed
65	18	3	09:00:00	Shared	10	confirmed
66	18	5	09:30:00	Shared	6	confirmed
67	19	1	07:30:00	Shared	11	confirmed
68	19	2	07:30:00	Shared	11	confirmed
69	19	6	07:30:00	Shared	11	confirmed
70	19	3	08:30:00	Shared	10	confirmed
71	20	5	09:00:00	Shared	6	confirmed
72	19	3	09:30:00	Shared	9	confirmed
73	21	3	07:30:00	Shared	10	Cancelled
74	21	1	06:30:00	Shared	11	Cancelled
75	21	2	06:30:00	Shared	11	Cancelled
76	22	1	08:00:00	Shared	11	confirmed
77	22	2	08:00:00	Shared	11	confirmed
78	22	6	08:00:00	Shared	11	confirmed
79	22	3	09:30:00	Shared	10	confirmed
80	22	5	09:30:00	Shared	6	confirmed
81	23	1	07:30:00	Shared	11	confirmed
82	23	2	07:30:00	Shared	11	confirmed
83	23	6	07:30:00	Shared	11	confirmed
84	23	3	08:30:00	Shared	10	confirmed
85	23	5	09:00:00	Shared	6	confirmed
86	23	3	09:30:00	Shared	9	confirmed
87	24	1	07:30:00	Shared	11	confirmed
88	24	2	07:30:00	Shared	11	confirmed
89	24	6	07:30:00	Shared	11	confirmed
90	24	3	08:30:00	Shared	10	confirmed
91	24	5	09:00:00	Shared	6	confirmed
92	25	1	07:30:00	Shared	10	confirmed
93	25	2	07:30:00	Shared	10	confirmed
94	25	6	07:30:00	Shared	10	confirmed
95	25	3	07:30:00	Shared	10	confirmed
96	25	5	08:30:00	Shared	6	confirmed
97	26	1	07:30:00	Shared	11	confirmed
98	26	2	07:30:00	Shared	11	confirmed
99	26	6	07:30:00	Shared	11	confirmed
100	26	3	08:30:00	Shared	10	confirmed
101	26	5	09:00:00	Shared	6	confirmed
102	27	4	08:00:00	Shared	8	confirmed
103	28	7	08:00:00	Shared	8	confirmed
104	29	1	07:30:00	Shared	10	confirmed
105	29	2	07:30:00	Shared	10	confirmed
106	29	6	07:30:00	Shared	10	confirmed
107	29	3	07:30:00	Shared	10	confirmed
108	29	5	08:30:00	Shared	6	confirmed
109	30	4	09:00:00	Private	8	confirmed
110	30	4	09:30:00	Shared	8	confirmed
111	31	1	07:30:00	Shared	11	confirmed
112	31	2	07:30:00	Shared	11	confirmed
113	31	3	08:30:00	Shared	10	confirmed
114	31	9	08:00:00	Private	10	confirmed
115	32	6	07:30:00	Shared	11	confirmed
116	32	5	09:00:00	Shared	6	confirmed
117	32	3	09:30:00	Shared	9	confirmed
118	33	1	07:30:00	Shared	11	confirmed
119	33	2	07:30:00	Shared	11	confirmed
120	33	3	08:30:00	Shared	10	confirmed
121	34	4	08:00:00	Shared	8	confirmed
122	35	3	07:30:00	Shared	9	confirmed
123	35	1	07:30:00	Shared	9	confirmed
124	35	2	07:30:00	Shared	9	confirmed
125	35	5	08:30:00	Shared	6	confirmed
126	36	1	07:30:00	Shared	11	confirmed
127	36	2	07:30:00	Shared	11	confirmed
128	36	6	07:30:00	Shared	11	confirmed
129	36	3	08:30:00	Shared	10	confirmed
130	36	5	09:00:00	Shared	6	confirmed
131	36	3	09:30:00	Shared	9	confirmed
132	37	1	07:30:00	Shared	11	confirmed
133	37	2	07:30:00	Shared	11	confirmed
134	37	6	07:30:00	Shared	11	confirmed
135	37	3	08:30:00	Shared	10	confirmed
136	37	5	09:00:00	Shared	6	confirmed
137	38	1	08:00:00	Shared	11	confirmed
138	38	2	08:00:00	Shared	11	confirmed
139	38	6	08:00:00	Shared	11	confirmed
140	38	3	09:00:00	Shared	10	confirmed
141	38	5	09:30:00	Shared	6	confirmed
142	39	1	07:30:00	Shared	11	confirmed
143	39	2	07:30:00	Shared	11	confirmed
144	39	6	07:30:00	Shared	11	confirmed
145	39	3	08:30:00	Shared	10	confirmed
146	39	5	09:00:00	Shared	6	confirmed
147	39	3	09:30:00	Shared	9	confirmed
148	40	7	09:30:00	Shared	8	confirmed
149	41	7	08:00:00	Shared	8	confirmed
150	42	4	08:30:00	Shared	8	confirmed
151	43	1	07:30:00	Shared	11	confirmed
152	43	2	07:30:00	Shared	11	confirmed
153	43	6	07:30:00	Shared	11	confirmed
154	43	3	08:30:00	Shared	10	confirmed
155	43	5	09:30:00	Shared	6	confirmed
156	44	1	07:30:00	Shared	11	confirmed
157	44	2	07:30:00	Shared	11	confirmed
158	44	6	07:30:00	Shared	11	confirmed
159	44	3	08:30:00	Shared	10	confirmed
160	44	5	09:00:00	Shared	6	confirmed
161	44	3	09:30:00	Shared	9	confirmed
162	45	2	08:30:00	Shared	11	confirmed
163	45	1	08:30:00	Shared	11	confirmed
164	45	6	08:30:00	Shared	11	confirmed
165	45	3	08:30:00	Shared	10	confirmed
166	45	3	09:00:00	Shared	9	confirmed
167	45	5	09:30:00	Shared	6	confirmed
168	45	6	08:30:00	Private	4	Cancelled
169	46	1	07:30:00	Shared	11	confirmed
170	46	2	07:30:00	Shared	11	confirmed
171	46	6	07:30:00	Shared	11	confirmed
172	46	3	08:30:00	Shared	10	confirmed
173	46	5	09:00:00	Shared	6	confirmed
174	47	1	07:00:00	Shared	11	confirmed
175	47	2	07:00:00	Shared	11	confirmed
176	47	6	07:00:00	Shared	11	confirmed
177	47	3	07:30:00	Shared	10	confirmed
178	47	5	08:00:00	Shared	6	confirmed
179	48	1	07:30:00	Shared	11	confirmed
180	48	2	07:30:00	Shared	11	confirmed
181	48	6	07:30:00	Shared	11	confirmed
182	48	3	08:30:00	Shared	10	confirmed
183	48	5	09:00:00	Shared	6	confirmed
184	48	3	09:30:00	Shared	9	confirmed
185	49	1	07:30:00	Shared	11	confirmed
186	49	2	07:30:00	Shared	11	confirmed
187	49	6	07:30:00	Shared	11	confirmed
188	49	3	08:30:00	Shared	10	confirmed
189	49	5	09:00:00	Shared	6	confirmed
190	50	1	08:30:00	Shared	11	confirmed
191	50	2	08:30:00	Shared	11	confirmed
192	50	6	08:30:00	Shared	11	confirmed
193	50	3	08:30:00	Shared	10	confirmed
194	50	5	09:00:00	Shared	6	confirmed
195	51	1	07:30:00	Shared	11	confirmed
196	51	2	07:30:00	Shared	11	confirmed
197	51	6	07:30:00	Shared	11	confirmed
198	51	3	08:30:00	Shared	10	confirmed
199	51	5	09:00:00	Shared	6	confirmed
200	52	7	08:30:00	Shared	7	confirmed
201	53	1	07:30:00	Shared	11	confirmed
202	53	2	07:30:00	Shared	11	confirmed
203	53	6	07:30:00	Shared	11	confirmed
204	53	3	08:30:00	Shared	10	confirmed
205	53	5	09:00:00	Shared	6	confirmed
206	53	3	09:30:00	Shared	9	confirmed
207	54	4	08:00:00	Shared	8	confirmed
208	55	1	07:30:00	Shared	11	confirmed
209	55	2	07:30:00	Shared	11	confirmed
210	55	6	07:30:00	Shared	11	confirmed
211	55	3	08:30:00	Shared	10	confirmed
212	55	5	09:00:00	Shared	6	confirmed
213	55	3	09:30:00	Shared	9	confirmed
214	56	1	07:30:00	Shared	11	confirmed
215	56	2	07:30:00	Shared	11	confirmed
216	56	6	07:30:00	Shared	11	confirmed
217	56	3	08:00:00	Shared	10	confirmed
218	56	5	09:00:00	Shared	6	confirmed
219	57	7	09:00:00	Shared	8	confirmed
220	58	1	08:30:00	Shared	11	confirmed
221	58	2	08:30:00	Shared	11	confirmed
222	58	6	08:30:00	Shared	11	confirmed
223	58	3	08:30:00	Shared	10	confirmed
224	58	5	08:30:00	Shared	6	confirmed
225	59	1	07:30:00	Shared	11	confirmed
226	59	2	07:30:00	Shared	11	confirmed
227	59	6	07:30:00	Shared	11	confirmed
228	59	3	08:00:00	Shared	10	confirmed
229	59	5	09:00:00	Shared	6	confirmed
230	60	1	07:30:00	Shared	11	confirmed
231	60	2	07:30:00	Shared	11	confirmed
232	60	6	07:30:00	Shared	11	confirmed
233	60	3	08:30:00	Shared	10	confirmed
234	60	5	09:00:00	Shared	6	confirmed
235	61	1	08:30:00	Shared	11	confirmed
236	61	2	08:30:00	Shared	11	confirmed
237	61	6	08:30:00	Shared	11	confirmed
238	61	3	08:30:00	Shared	10	confirmed
239	61	5	09:30:00	Shared	6	confirmed
240	61	9	09:30:00	Shared	7	confirmed
241	62	1	08:30:00	Shared	11	confirmed
242	62	2	08:30:00	Shared	11	confirmed
243	62	6	08:30:00	Shared	11	confirmed
244	62	3	09:30:00	Shared	10	confirmed
245	62	5	10:00:00	Shared	6	confirmed
246	62	4	08:30:00	Shared	8	confirmed
247	63	7	07:30:00	Shared	8	confirmed
248	64	4	08:00:00	Shared	8	confirmed
249	65	6	08:30:00	Shared	10	confirmed
250	65	1	09:00:00	Shared	10	confirmed
251	65	2	09:00:00	Shared	10	confirmed
252	65	3	09:30:00	Shared	10	confirmed
253	65	5	10:00:00	Shared	6	confirmed
254	66	1	07:00:00	Shared	\N	confirmed
255	66	2	07:00:00	Shared	\N	confirmed
256	66	6	07:00:00	Shared	\N	confirmed
257	66	3	07:30:00	Shared	10	confirmed
258	66	5	09:00:00	Shared	6	confirmed
259	67	1	07:30:00	Shared	11	confirmed
260	67	2	07:30:00	Shared	11	confirmed
261	67	6	07:30:00	Shared	11	confirmed
262	67	3	08:30:00	Shared	10	confirmed
263	67	5	09:00:00	Shared	6	confirmed
264	68	4	07:30:00	Shared	7	confirmed
265	69	1	07:00:00	Shared	\N	confirmed
266	69	2	07:00:00	Shared	\N	confirmed
267	69	6	07:00:00	Shared	\N	confirmed
268	69	3	07:30:00	Shared	10	confirmed
269	69	5	09:00:00	Shared	6	confirmed
270	70	1	07:00:00	Shared	\N	confirmed
271	70	2	07:00:00	Shared	\N	confirmed
272	70	6	07:00:00	Shared	\N	confirmed
273	70	3	07:30:00	Shared	10	confirmed
274	70	5	08:00:00	Shared	6	confirmed
275	71	1	08:30:00	Shared	11	confirmed
276	71	2	08:30:00	Shared	11	confirmed
277	71	6	08:30:00	Shared	11	confirmed
278	71	3	09:30:00	Shared	10	confirmed
279	71	5	10:00:00	Shared	6	confirmed
280	72	4	08:00:00	Shared	8	confirmed
281	73	1	08:30:00	Shared	11	confirmed
282	73	2	08:30:00	Shared	11	confirmed
283	73	6	08:30:00	Shared	11	confirmed
284	73	3	09:30:00	Shared	10	confirmed
285	73	5	10:00:00	Shared	6	confirmed
\.


--
-- Name: change_log_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.change_log_log_id_seq', 1, false);


--
-- Name: departure_departure_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.departure_departure_id_seq', 1, false);


--
-- Name: discount_discount_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.discount_discount_id_seq', 1, false);


--
-- Name: note_note_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.note_note_id_seq', 148, true);


--
-- Name: option_availability_availability_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.option_availability_availability_id_seq', 1, false);


--
-- Name: option_blocked_period_blocked_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.option_blocked_period_blocked_id_seq', 1, false);


--
-- Name: option_start_time_start_time_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.option_start_time_start_time_id_seq', 1, false);


--
-- Name: platform_commission_commission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.platform_commission_commission_id_seq', 1, false);


--
-- Name: platform_option_platform_option_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.platform_option_platform_option_id_seq', 323, true);


--
-- Name: platform_platform_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.platform_platform_id_seq', 4, true);


--
-- Name: platform_tour_platform_tour_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.platform_tour_platform_tour_id_seq', 31, true);


--
-- Name: port_port_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.port_port_id_seq', 3, true);


--
-- Name: pricing_history_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pricing_history_history_id_seq', 1, false);


--
-- Name: pricing_pricing_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pricing_pricing_id_seq', 35, true);


--
-- Name: schedule_platform_entry_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.schedule_platform_entry_entry_id_seq', 865, true);


--
-- Name: ship_docking_docking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ship_docking_docking_id_seq', 73, true);


--
-- Name: ship_ship_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ship_ship_id_seq', 21, true);


--
-- Name: shore_excursion_shorex_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.shore_excursion_shorex_id_seq', 9, true);


--
-- Name: tour_schedule_schedule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tour_schedule_schedule_id_seq', 285, true);


--
-- Name: change_log change_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.change_log
    ADD CONSTRAINT change_log_pkey PRIMARY KEY (log_id);


--
-- Name: departure departure_option_id_departure_date_start_time_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departure
    ADD CONSTRAINT departure_option_id_departure_date_start_time_key UNIQUE (option_id, departure_date, start_time);


--
-- Name: departure departure_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departure
    ADD CONSTRAINT departure_pkey PRIMARY KEY (departure_id);


--
-- Name: discount discount_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount
    ADD CONSTRAINT discount_pkey PRIMARY KEY (discount_id);


--
-- Name: discount discount_promo_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount
    ADD CONSTRAINT discount_promo_code_key UNIQUE (promo_code);


--
-- Name: note note_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note
    ADD CONSTRAINT note_pkey PRIMARY KEY (note_id);


--
-- Name: option_availability option_availability_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_availability
    ADD CONSTRAINT option_availability_pkey PRIMARY KEY (availability_id);


--
-- Name: option_blocked_period option_blocked_period_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_blocked_period
    ADD CONSTRAINT option_blocked_period_pkey PRIMARY KEY (blocked_id);


--
-- Name: option_start_time option_start_time_availability_id_start_time_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_start_time
    ADD CONSTRAINT option_start_time_availability_id_start_time_key UNIQUE (availability_id, start_time);


--
-- Name: option_start_time option_start_time_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_start_time
    ADD CONSTRAINT option_start_time_pkey PRIMARY KEY (start_time_id);


--
-- Name: platform_commission platform_commission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_commission
    ADD CONSTRAINT platform_commission_pkey PRIMARY KEY (commission_id);


--
-- Name: platform platform_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform
    ADD CONSTRAINT platform_name_key UNIQUE (name);


--
-- Name: platform_option platform_option_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_option
    ADD CONSTRAINT platform_option_pkey PRIMARY KEY (platform_option_id);


--
-- Name: platform platform_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform
    ADD CONSTRAINT platform_pkey PRIMARY KEY (platform_id);


--
-- Name: platform_tour platform_tour_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_tour
    ADD CONSTRAINT platform_tour_pkey PRIMARY KEY (platform_tour_id);


--
-- Name: platform_tour platform_tour_platform_id_external_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_tour
    ADD CONSTRAINT platform_tour_platform_id_external_id_key UNIQUE (platform_id, external_id);


--
-- Name: port port_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.port
    ADD CONSTRAINT port_name_key UNIQUE (name);


--
-- Name: port port_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.port
    ADD CONSTRAINT port_pkey PRIMARY KEY (port_id);


--
-- Name: pricing_history pricing_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricing_history
    ADD CONSTRAINT pricing_history_pkey PRIMARY KEY (history_id);


--
-- Name: pricing pricing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricing
    ADD CONSTRAINT pricing_pkey PRIMARY KEY (pricing_id);


--
-- Name: pricing pricing_shorex_id_platform_id_platform_tour_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricing
    ADD CONSTRAINT pricing_shorex_id_platform_id_platform_tour_id_key UNIQUE (shorex_id, platform_id, platform_tour_id);


--
-- Name: schedule_platform_entry schedule_platform_entry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_platform_entry
    ADD CONSTRAINT schedule_platform_entry_pkey PRIMARY KEY (entry_id);


--
-- Name: ship_docking ship_docking_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ship_docking
    ADD CONSTRAINT ship_docking_pkey PRIMARY KEY (docking_id);


--
-- Name: ship_docking ship_docking_ship_id_date_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ship_docking
    ADD CONSTRAINT ship_docking_ship_id_date_key UNIQUE (ship_id, date);


--
-- Name: ship ship_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ship
    ADD CONSTRAINT ship_name_key UNIQUE (name);


--
-- Name: ship ship_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ship
    ADD CONSTRAINT ship_pkey PRIMARY KEY (ship_id);


--
-- Name: shore_excursion shore_excursion_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shore_excursion
    ADD CONSTRAINT shore_excursion_name_key UNIQUE (name);


--
-- Name: shore_excursion shore_excursion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shore_excursion
    ADD CONSTRAINT shore_excursion_pkey PRIMARY KEY (shorex_id);


--
-- Name: tour_option tour_option_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tour_option
    ADD CONSTRAINT tour_option_pkey PRIMARY KEY (option_id);


--
-- Name: tour tour_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tour
    ADD CONSTRAINT tour_pkey PRIMARY KEY (tour_id);


--
-- Name: tour_schedule tour_schedule_docking_id_shorex_id_tour_type_start_time_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tour_schedule
    ADD CONSTRAINT tour_schedule_docking_id_shorex_id_tour_type_start_time_key UNIQUE (docking_id, shorex_id, tour_type, start_time);


--
-- Name: tour_schedule tour_schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tour_schedule
    ADD CONSTRAINT tour_schedule_pkey PRIMARY KEY (schedule_id);


--
-- Name: idx_availability_option; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_availability_option ON public.option_availability USING btree (option_id);


--
-- Name: idx_blocked_period_dates; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_blocked_period_dates ON public.option_blocked_period USING btree (availability_id, date_from, date_to);


--
-- Name: idx_change_log_changed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_change_log_changed_at ON public.change_log USING btree (changed_at DESC);


--
-- Name: idx_change_log_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_change_log_entity ON public.change_log USING btree (entity_type, entity_id);


--
-- Name: idx_change_log_review; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_change_log_review ON public.change_log USING btree (review) WHERE (reviewed = false);


--
-- Name: idx_commission_option; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commission_option ON public.platform_commission USING btree (option_id) WHERE (option_id IS NOT NULL);


--
-- Name: idx_commission_platform; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commission_platform ON public.platform_commission USING btree (platform_id);


--
-- Name: idx_commission_tour; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commission_tour ON public.platform_commission USING btree (tour_id) WHERE (tour_id IS NOT NULL);


--
-- Name: idx_departure_closed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_departure_closed ON public.departure USING btree (manually_closed) WHERE (manually_closed = true);


--
-- Name: idx_departure_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_departure_date ON public.departure USING btree (departure_date);


--
-- Name: idx_departure_docking; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_departure_docking ON public.departure USING btree (docking_id) WHERE (docking_id IS NOT NULL);


--
-- Name: idx_departure_open; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_departure_open ON public.departure USING btree (departure_date, status) WHERE (status = 'open'::text);


--
-- Name: idx_departure_option; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_departure_option ON public.departure USING btree (option_id);


--
-- Name: idx_discount_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_discount_active ON public.discount USING btree (valid_from, valid_to) WHERE (status = 'active'::text);


--
-- Name: idx_discount_option; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_discount_option ON public.discount USING btree (option_id) WHERE (option_id IS NOT NULL);


--
-- Name: idx_discount_platform; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_discount_platform ON public.discount USING btree (platform_id) WHERE (platform_id IS NOT NULL);


--
-- Name: idx_discount_promo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_discount_promo ON public.discount USING btree (promo_code) WHERE (promo_code IS NOT NULL);


--
-- Name: idx_docking_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_docking_date ON public.ship_docking USING btree (date);


--
-- Name: idx_docking_ship; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_docking_ship ON public.ship_docking USING btree (ship_id);


--
-- Name: idx_entry_schedule; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_entry_schedule ON public.schedule_platform_entry USING btree (schedule_id);


--
-- Name: idx_note_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_note_created_at ON public.note USING btree (created_at DESC);


--
-- Name: idx_note_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_note_entity ON public.note USING btree (entity_type, entity_id);


--
-- Name: idx_note_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_note_type ON public.note USING btree (note_type);


--
-- Name: idx_platform_option_tour; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_platform_option_tour ON public.platform_option USING btree (platform_tour_id);


--
-- Name: idx_platform_option_vex; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_platform_option_vex ON public.platform_option USING btree (vex_option_id);


--
-- Name: idx_pricing_pending_review; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pricing_pending_review ON public.pricing USING btree (review) WHERE (reviewed = false);


--
-- Name: idx_pricing_shorex; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pricing_shorex ON public.pricing USING btree (shorex_id);


--
-- Name: idx_schedule_docking; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_schedule_docking ON public.tour_schedule USING btree (docking_id);


--
-- Name: idx_schedule_shorex; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_schedule_shorex ON public.tour_schedule USING btree (shorex_id);


--
-- Name: idx_tour_option_ship; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tour_option_ship ON public.tour_option USING btree (ship_id);


--
-- Name: idx_tour_option_tour; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tour_option_tour ON public.tour_option USING btree (tour_id);


--
-- Name: departure departure_availability_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departure
    ADD CONSTRAINT departure_availability_id_fkey FOREIGN KEY (availability_id) REFERENCES public.option_availability(availability_id);


--
-- Name: departure departure_docking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departure
    ADD CONSTRAINT departure_docking_id_fkey FOREIGN KEY (docking_id) REFERENCES public.ship_docking(docking_id);


--
-- Name: departure departure_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departure
    ADD CONSTRAINT departure_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.tour_option(option_id);


--
-- Name: discount discount_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount
    ADD CONSTRAINT discount_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.tour_option(option_id);


--
-- Name: discount discount_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount
    ADD CONSTRAINT discount_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES public.platform(platform_id);


--
-- Name: discount discount_shorex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount
    ADD CONSTRAINT discount_shorex_id_fkey FOREIGN KEY (shorex_id) REFERENCES public.shore_excursion(shorex_id);


--
-- Name: discount discount_tour_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount
    ADD CONSTRAINT discount_tour_id_fkey FOREIGN KEY (tour_id) REFERENCES public.tour(tour_id);


--
-- Name: option_availability option_availability_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_availability
    ADD CONSTRAINT option_availability_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.tour_option(option_id);


--
-- Name: option_blocked_period option_blocked_period_availability_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_blocked_period
    ADD CONSTRAINT option_blocked_period_availability_id_fkey FOREIGN KEY (availability_id) REFERENCES public.option_availability(availability_id) ON DELETE CASCADE;


--
-- Name: option_start_time option_start_time_availability_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.option_start_time
    ADD CONSTRAINT option_start_time_availability_id_fkey FOREIGN KEY (availability_id) REFERENCES public.option_availability(availability_id) ON DELETE CASCADE;


--
-- Name: platform_commission platform_commission_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_commission
    ADD CONSTRAINT platform_commission_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.tour_option(option_id);


--
-- Name: platform_commission platform_commission_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_commission
    ADD CONSTRAINT platform_commission_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES public.platform(platform_id);


--
-- Name: platform_commission platform_commission_shorex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_commission
    ADD CONSTRAINT platform_commission_shorex_id_fkey FOREIGN KEY (shorex_id) REFERENCES public.shore_excursion(shorex_id);


--
-- Name: platform_commission platform_commission_tour_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_commission
    ADD CONSTRAINT platform_commission_tour_id_fkey FOREIGN KEY (tour_id) REFERENCES public.tour(tour_id);


--
-- Name: platform_option platform_option_platform_tour_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_option
    ADD CONSTRAINT platform_option_platform_tour_id_fkey FOREIGN KEY (platform_tour_id) REFERENCES public.platform_tour(platform_tour_id);


--
-- Name: platform_option platform_option_ship_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_option
    ADD CONSTRAINT platform_option_ship_id_fkey FOREIGN KEY (ship_id) REFERENCES public.ship(ship_id);


--
-- Name: platform_option platform_option_vex_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_option
    ADD CONSTRAINT platform_option_vex_option_id_fkey FOREIGN KEY (vex_option_id) REFERENCES public.tour_option(option_id);


--
-- Name: platform_tour platform_tour_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_tour
    ADD CONSTRAINT platform_tour_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES public.platform(platform_id);


--
-- Name: platform_tour platform_tour_tour_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_tour
    ADD CONSTRAINT platform_tour_tour_id_fkey FOREIGN KEY (tour_id) REFERENCES public.tour(tour_id);


--
-- Name: pricing pricing_platform_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricing
    ADD CONSTRAINT pricing_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES public.platform(platform_id);


--
-- Name: pricing pricing_platform_tour_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricing
    ADD CONSTRAINT pricing_platform_tour_id_fkey FOREIGN KEY (platform_tour_id) REFERENCES public.platform_tour(platform_tour_id);


--
-- Name: pricing pricing_shorex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricing
    ADD CONSTRAINT pricing_shorex_id_fkey FOREIGN KEY (shorex_id) REFERENCES public.shore_excursion(shorex_id);


--
-- Name: pricing pricing_vex_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricing
    ADD CONSTRAINT pricing_vex_option_id_fkey FOREIGN KEY (vex_option_id) REFERENCES public.tour_option(option_id);


--
-- Name: schedule_platform_entry schedule_platform_entry_platform_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_platform_entry
    ADD CONSTRAINT schedule_platform_entry_platform_option_id_fkey FOREIGN KEY (platform_option_id) REFERENCES public.platform_option(platform_option_id);


--
-- Name: schedule_platform_entry schedule_platform_entry_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_platform_entry
    ADD CONSTRAINT schedule_platform_entry_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.tour_schedule(schedule_id);


--
-- Name: schedule_platform_entry schedule_platform_entry_vex_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_platform_entry
    ADD CONSTRAINT schedule_platform_entry_vex_option_id_fkey FOREIGN KEY (vex_option_id) REFERENCES public.tour_option(option_id);


--
-- Name: ship_docking ship_docking_port_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ship_docking
    ADD CONSTRAINT ship_docking_port_id_fkey FOREIGN KEY (port_id) REFERENCES public.port(port_id);


--
-- Name: ship_docking ship_docking_ship_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ship_docking
    ADD CONSTRAINT ship_docking_ship_id_fkey FOREIGN KEY (ship_id) REFERENCES public.ship(ship_id);


--
-- Name: shore_excursion shore_excursion_primary_port_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shore_excursion
    ADD CONSTRAINT shore_excursion_primary_port_id_fkey FOREIGN KEY (primary_port_id) REFERENCES public.port(port_id);


--
-- Name: tour_option tour_option_ship_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tour_option
    ADD CONSTRAINT tour_option_ship_id_fkey FOREIGN KEY (ship_id) REFERENCES public.ship(ship_id);


--
-- Name: tour_option tour_option_tour_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tour_option
    ADD CONSTRAINT tour_option_tour_id_fkey FOREIGN KEY (tour_id) REFERENCES public.tour(tour_id);


--
-- Name: tour_schedule tour_schedule_docking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tour_schedule
    ADD CONSTRAINT tour_schedule_docking_id_fkey FOREIGN KEY (docking_id) REFERENCES public.ship_docking(docking_id);


--
-- Name: tour_schedule tour_schedule_shorex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tour_schedule
    ADD CONSTRAINT tour_schedule_shorex_id_fkey FOREIGN KEY (shorex_id) REFERENCES public.shore_excursion(shorex_id);


--
-- Name: tour tour_shorex_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tour
    ADD CONSTRAINT tour_shorex_id_fkey FOREIGN KEY (shorex_id) REFERENCES public.shore_excursion(shorex_id);


--
-- PostgreSQL database dump complete
--

\unrestrict ywpEtCdrvVjKv4mwtjYV1lxIqYPRJVBSduZcloGOoLDXU0nxAvXDaoPtmlHIGAl

