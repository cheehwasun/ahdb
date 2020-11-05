-- PostgreSQL 11.9
-- timescaledb 1.4.2

-- date 2019-10-04 23:43:31
create table raw_log
(
    time    timestamp with time zone not null,
    type    text                     not null,
    raw_str text                     not null
);

alter table raw_log
    owner to postgres;

create index raw_log_time_idx
    on raw_log (time desc);

create trigger ts_insert_blocker
    before insert
    on raw_log
    for each row
execute procedure "_timescaledb_internal".insert_blocker();


create table raw_data
(
    time       timestamp with time zone not null,
    type       text                     not null,
    account_id text                     not null,
    raw_str    text                     not null
);

alter table raw_data
    owner to postgres;

create index raw_data_time_idx
    on raw_data (time desc);

create trigger ts_insert_blocker
    before insert
    on raw_data
    for each row
execute procedure "_timescaledb_internal".insert_blocker();

-- date 2019-10-04 23:50:32
create table item_desc
(
    id          text not null,
    name        text not null,
    item_class  text not null,
    sub_class   text,
    item_lv     integer,
    require_lv  integer,
    vendor_buy  integer,
    vendor_sell integer,
    icon        text
);

create index item_desc_id_idx
    on item_desc (id);

create index item_desc_name_idx
    on item_desc (name);

-- date 2019-10-08 09:17:41
create table item_scan
(
    item_id      text                     not null,
    min_buyout   integer                  not null,
    market_value integer                  not null,
    num_auctions integer                  not null,
    quantity     integer                  not null,
    scan_time    timestamp with time zone not null,
    realm        text                     not null,
    add_time     timestamp with time zone not null
);

SELECT create_hypertable('item_scan', 'scan_time');

create index item_scan_scan_time_item_id_idx
    on item_scan (scan_time DESC, item_id);

-- date 2019-10-22 12:23:46
create table account_stats
(
    account_id text                     not null,
    chars      text                     not null,
    power      integer,
    last_push  timestamp with time zone not null

);

create index account_stats_account_id_idx
    on account_stats (account_id);

-- date 2019-10-23 11:27:44
CREATE TABLE biz_cache
(
    id        text,
    cache_str text
);

-- date 2020-11-05 14:33:51
CREATE VIEW view_hourly(item_id, hourly_time_bucket, hourly_avg_min_buyout, hourly_avg_market_value,
                        hourly_avg_quantity, hourly_avg_num_auctions) AS
SELECT item_scan.item_id,
       time_bucket('01:00:00'::interval, item_scan.scan_time) AS hourly_time_bucket,
       avg(item_scan.min_buyout)                              AS hourly_avg_min_buyout,
       avg(item_scan.market_value)                            AS hourly_avg_market_value,
       avg(item_scan.quantity)                                AS hourly_avg_quantity,
       avg(item_scan.num_auctions)                            AS hourly_avg_num_auctions
FROM item_scan
GROUP BY item_scan.item_id, (time_bucket('01:00:00'::interval, item_scan.scan_time));

CREATE MATERIALIZED VIEW view_daily AS
WITH bounds AS (
    SELECT view_hourly_1.item_id                                                                        AS id0,
           time_bucket('1 day'::interval, view_hourly_1.hourly_time_bucket)                             AS daily_time_bucket0,
           (avg(view_hourly_1.hourly_avg_market_value) - stddev(view_hourly_1.hourly_avg_market_value)) AS low,
           (avg(view_hourly_1.hourly_avg_market_value) + stddev(view_hourly_1.hourly_avg_market_value)) AS high
    FROM view_hourly view_hourly_1
    GROUP BY view_hourly_1.item_id, (time_bucket('1 day'::interval, view_hourly_1.hourly_time_bucket))
)
SELECT view_hourly.item_id,
       time_bucket('1 day'::interval, view_hourly.hourly_time_bucket) AS daily_time_bucket,
       avg(view_hourly.hourly_avg_min_buyout)                         AS daily_avg_min_buyout,
       avg(view_hourly.hourly_avg_market_value)                       AS daily_avg_market_value,
       avg(view_hourly.hourly_avg_quantity)                           AS daily_avg_quantity,
       avg(view_hourly.hourly_avg_num_auctions)                       AS daily_avg_num_auctions
FROM view_hourly,
     bounds
WHERE ((view_hourly.hourly_time_bucket < (now())::date) AND (view_hourly.item_id = bounds.id0) AND
       (time_bucket('1 day'::interval, view_hourly.hourly_time_bucket) = bounds.daily_time_bucket0) AND
       ((view_hourly.hourly_avg_market_value >= bounds.low) AND
        (view_hourly.hourly_avg_market_value <= bounds.high)))
GROUP BY view_hourly.item_id, (time_bucket('1 day'::interval, view_hourly.hourly_time_bucket));
