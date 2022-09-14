-- Table Customer --
CREATE TABLE Customer (
    id int primary key,
    fname varchar,
    lname varchar,
    street varchar,
    town varchar,
    postal_code varchar
);

-- Table Station --
CREATE TABLE Station (
    id int primary key,
    name varchar,
    open_time varchar,
    close_time varchar,
    stop_delay int,
    street varchar,
    town varchar,
    postal_code varchar
);

-- Table Train --
CREATE TABLE Train (
    id int primary key,
    name varchar,
    description varchar,
    seat_avail int,
    top_speed int,
    cost_per_km int
);

-- Table Rail_Line --
CREATE TABLE Rail_Line (
    line_id int primary key,
    speed_limit int
);

-- Table Passes_Thru_SRL --
CREATE TABLE Passes_Thru_SRL (
    line_id int primary key,
    station_id int primary key,
    distance int,
    CONSTRAINT FK1_SRL FOREIGN KEY (line_id) REFERENCES Rail_Line (line_id) ON DELETE CASCADE,
    CONSTRAINT FK2_SRL FOREIGN KEY (station_id) REFERENCES Station (id) ON DELETE CASCADE
);

-- Table Route --
CREATE TABLE Route (
    route_id int primary key
);

-- Table Passes_Thru_SR
CREATE TABLE Passes_Thru_SR (
    route_id int primary key,
    station_id int primary key,
    stops bool,
    CONSTRAINT FK1_SR FOREIGN KEY (route_id) REFERENCES Route (route_id) ON DELETE CASCADE,
    CONSTRAINT FK2_SR FOREIGN KEY (station_id) REFERENCES Station (id) ON DELETE CASCADE
);

-- Table Route_Schedule --
CREATE TABLE Route_Schedule (
    route_id int primary key,
    day int, -- day of week, from Monday (1) to Sunday (7)
    time time,
    train_id int primary key,
    CONSTRAINT FK1_RS FOREIGN KEY (route_id) REFERENCES Route (route_id) ON DELETE CASCADE,
    CONSTRAINT FK2_RS FOREIGN KEY (train_id) REFERENCES Train (id) ON DELETE CASCADE
);

-- Table Reservation--
CREATE TABLE Reservation(
    reservation_id int primary key,
    customer_id int,
    route_id int,
    train_id int,
    price int,
    CONSTRAINT FK_RS1 FOREIGN KEY (customer_id) REFERENCES Customer(id) ON DELETE CASCADE,
    CONSTRAINT FK_RS2 FOREIGN KEY (route_id) REFERENCES Route_Schedule(route_id) ON DELETE CASCADE,
    CONSTRAINT FK_RS3 FOREIGN KEY (train_id) REFERENCES Train(id) ON DELETE CASCADE
);

-- Table Ticket--
CREATE TABLE Ticket(
    ticket_id int primary key,
    reservation_id int,
    customer_id int,
    CONSTRAINT FK_RS1 FOREIGN KEY (reservation_id) REFERENCES Reservation (reservation_id) ON DELETE CASCADE,
    CONSTRAINT FK_RS2 FOREIGN KEY (customer_id) REFERENCES Customer (id) ON DELETE CASCADE
);

-- Table Clock --
CREATE TABLE CLOCK (
    p_date timestamp primary key
);

-- Phase 2: Database Implementation -> Data Generation/Implementation of Operations in DML

-- 1. Update Customer List
-- a) Add New Customer
CREATE OR REPLACE FUNCTION add_new_customer(arg_id int, arg_fname varchar, arg_lname varchar, arg_street varchar, arg_town varchar, arg_postal_code varchar)
RETURNS int
AS $$
    BEGIN
        INSERT INTO Customer VALUES (arg_id, arg_fname, arg_lname, arg_street, arg_town, arg_postal_code);
        return arg_id;
    END;
    $$ LANGUAGE plpgsql;

-- b) Edit Customer Data
CREATE OR REPLACE FUNCTION modify_customer_name(arg_id int, new_fname varchar, new_lname varchar)
RETURNS SETOF Customer
AS $$
    BEGIN
        UPDATE Customer
        SET fname = new_fname, lname = new_lname
        WHERE id = arg_id;

        RETURN QUERY
            SELECT *
            FROM Customer c
            WHERE c.id = arg_id;
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION modify_customer_address(arg_id int, new_street varchar, new_town varchar, new_postal_code varchar)
RETURNS SETOF Customer
AS $$
    BEGIN
        UPDATE Customer
        SET street = new_street, town = new_town, postal_code = new_postal_code
        WHERE id = arg_id;

        RETURN QUERY
            SELECT *
            FROM Customer c
            WHERE c.id = arg_id;
    END;
    $$ LANGUAGE plpgsql;

-- c) View Customer Data
CREATE OR REPLACE FUNCTION view_customer_data(arg_id int)
RETURNS SETOF Customer
AS $$
    BEGIN
        RETURN QUERY
            SELECT *
            FROM Customer c
            WHERE c.id = arg_id;
    END;
    $$ LANGUAGE plpgsql;

-- 2. Find  Travel Between Two Stations
-- a) Single Route Trip Search
CREATE OR REPLACE FUNCTION single_route_trip(depart_station_route int, destination_station_route int, specified_day_week int)
RETURNS SETOF route
AS $$
  BEGIN

    CREATE TEMP TABLE  depart_station
        AS
        SELECT route_id
        FROM Passes_Thru_SR
        WHERE Passes_Thru_SR.station_id = depart_station_route;

    CREATE TEMP TABLE destination_station
        AS
        SELECT route_id
        FROM Passes_Thru_SR
        WHERE Passes_Thru_SR .station_id = destination_station_route;

    CREATE TEMP TABLE two_stations
        AS
        SELECT depart_station.route_id
        FROM depart_station
            INNER JOIN destination_station
                ON destination_station.route_id = destination_station.route_id;

    RETURN QUERY
      SELECT DISTINCT two_stations.route_id
      FROM two_stations
          INNER JOIN Route_Schedule
              ON two_stations.route_id = Route_Schedule.route_id
      WHERE Route_Schedule.day = specified_day_week;
      
  END
$$ LANGUAGE plpgsql;

-- b) Combination Route Trip Search
CREATE OR REPLACE FUNCTION combination_route_trip(depart_station_route int, destination_station_route int, specified_day_week int)
RETURNS SETOF route
AS $$
  BEGIN

    CREATE TEMP TABLE depart_station_route
        AS
        SELECT route_id
        FROM Passes_Thru_SR
        WHERE Passes_Thru_SR.station_id = depart_station_route;

    CREATE TEMP TABLE destination_station_route
        AS
        SELECT route_id
        FROM Passes_Thru_SR
        WHERE Passes_Thru_SR.station_id = destination_station_route;

    CREATE TEMP TABLE two_stations
        AS
        SELECT depart_station_route.route_id
        FROM depart_station_route
            INNER JOIN destination_station_route
                ON depart_station_route.route_id = destination_station_route.route_id;

    RETURN QUERY
        SELECT DISTINCT two_stations.route_id
      FROM two_stations
          INNER JOIN Route_Schedule
              ON two_stations.route_id = Route_Schedule. route_id
      WHERE Route_Schedule.day = specified_day_week;
  END
$$ LANGUAGE plpgsql;

-- 3. Add Reservation
-- Book a specified passenger/customer along all legs of the specified route(s) on a given day
-- The reservation is booked, but not ticketed. The passenger MUST pay in order to get the ticket (Function #4)
-- Inputs: Passenger, Route_Schedule, Reservation
CREATE OR REPLACE FUNCTION add_reservation(arg_reservation_id int, arg_customer_id int, arg_route_id int, arg_train_id int, arg_price int)
RETURNS SETOF Reservation
AS $$
    BEGIN
        INSERT INTO Reservation VALUES (arg_reservation_id, arg_customer_id, arg_route_id, arg_train_id, arg_price);
        return arg_reservation_id;
    END;
$$ LANGUAGE plpgsql;

-- 4. Get Ticket (for a Reservation)
-- Ticket a booked reservation when the passenger pays the total amount --
CREATE OR REPLACE FUNCTION get_ticket(arg_ticket_id int, arg_reservation_id int, arg_price int)
RETURNS Ticket
AS $$
DECLARE
    paid_ticket_value int;
    this_customer int;
    BEGIN
        paid_ticket_value := (
            SELECT price
            FROM Reservation
            WHERE reservation_id=arg_reservation_id
        );
        this_customer := (
            SELECT customer_id
            FROM Reservation
            WHERE reservation_id=arg_reservation_id
        );
        IF (arg_price >= paid_ticket_value) THEN
            INSERT INTO Ticket VALUES (arg_ticket_id, arg_reservation_id, this_customer);
        END IF;
        RETURN QUERY
            SELECT *
            FROM Ticket
            WHERE ticket_id=arg_ticket_id;
    END;
$$ LANGUAGE plpgsql;

-- 5. Advanced Searches --
-- a) Find all trains that pass through a specific station at a specific day/time combination
CREATE OR REPLACE FUNCTION train_passes_thru_station_at_day_time(arg_station_id int, day_of_week int, arg_time time)
RETURNS SETOF Train
AS $$
    BEGIN
        CREATE OR REPLACE VIEW potential_routes AS
            SELECT route_id, train_id
            FROM Route_Schedule
            WHERE day=day_of_week and time=arg_time;
        CREATE OR REPLACE VIEW result_train_ids AS
            SELECT train_id
            FROM potential_routes NATURAL JOIN Passes_Thru_SR
            WHERE station_id=arg_station_id;
        RETURN QUERY
            SELECT *
            FROM Train t JOIN result_train_ids rti on t.id = rti.train_id;
    END;
$$ LANGUAGE plpgsql;

-- b) Find the routes that travel more than one rail line
CREATE OR REPLACE FUNCTION routes_more_than_one_rail_line()
RETURNS SETOF Route
AS $$
    BEGIN
        CREATE OR REPLACE VIEW route_rail_line_combination AS
            SELECT srl.line_id, sr.route_id
            FROM Passes_Thru_SRL srl JOIN Passes_thru_SR sr on srl.station_id=sr.station_id;
        CREATE OR REPLACE VIEW result_route_ids AS
            SELECT route_id
            FROM route_rail_line_combination
            GROUP BY route_id
            HAVING count(line_id) > 1;
        RETURN QUERY
            SELECT *
            FROM Route r JOIN result_route_ids rri on r.route_id = rri.route_id;
    END;
$$ LANGUAGE plpgsql;

-- c) Rank the trains that are scheduled for more than one route
CREATE OR REPLACE FUNCTION rank_trains_on_multiple_routes()
RETURNS SETOF Train
AS $$
    BEGIN
        CREATE OR REPLACE VIEW result_train_ids AS
            SELECT train_id
            FROM Route_Schedule
            GROUP BY train_id
            HAVING count(route_id) > 1;
        RETURN QUERY
            SELECT *
            FROM Train t JOIN result_train_ids rti on t.id = rti.train_id;
    END;
$$ LANGUAGE plpgsql;

-- d) Find routes that pass through the same stations but don't have the same stops
CREATE OR REPLACE FUNCTION similar_routes_dissimilar_stops()
RETURNS SETOF Route
AS $$
    BEGIN
        SELECT DISTINCT A.route_id
      FROM Passes_Thru_SR AS A
           JOIN Passes_Thru_SR AS B
          on A.route_id <> B.route_id
              AND NULL
              WHERE A.station_id = B.station_id AND B.route_id;
    END;
$$ LANGUAGE plpgsql;

-- e) Find any stations through which all trains pass through
CREATE OR REPLACE FUNCTION stations_all_trains()
RETURNS SETOF Station
AS $$
    DECLARE
        num_trains int;
    BEGIN
        num_trains := (
            SELECT count(*)
            FROM Train
        );
        CREATE OR REPLACE VIEW stations_all_trains AS
            SELECT station_id
            FROM Passes_Thru_SR NATURAL JOIN Route_Schedule
            GROUP BY station_id
            HAVING count(train_id)=num_trains;
        RETURN QUERY
            SELECT *
            FROM Station JOIN stations_all_trains ON id=station_id;
    END;
$$ LANGUAGE plpgsql;

-- f) Find all the trains that do not stop at a specific station
CREATE OR REPLACE FUNCTION trains_no_stations()
RETURNS SETOF Train
AS $$
    BEGIN
        CREATE OR REPLACE VIEW stopping_trains AS
            SELECT train_id
            FROM Passes_Thru_SR NATURAL JOIN Route_Schedule
            WHERE stops=True;
        CREATE OR REPLACE VIEW non_stopping_trains AS
            SELECT id
            FROM Train
            EXCEPT
                SELECT train_id id
                FROM stopping_trains;
        RETURN QUERY
            SELECT *
            FROM Train NATURAL JOIN non_stopping_trains;
    END;
$$ LANGUAGE plpgsql;

-- g) Find routes that stop at least at XX % of the stations they visit
CREATE OR REPLACE FUNCTION route_percentage_stop(arg_pct int)
RETURNS SETOF Route
AS $$
    BEGIN
        CREATE TEMP TABLE Percent_1 AS SELECT route_id,
                                      COUNT(*)
        FROM Station
        GROUP BY route_id;

        CREATE TEMP TABLE Percent_2  AS SELECT route_id,
                                               COUNT(*)
        FROM Passes_Thru_SR
        GROUP BY route_id;

        RETURN QUERY

          SELECT Percent_1.route_id
          FROM Percent_2
                   JOIN Percent_1
                              ON Percent_1.route_id = Percent_2.route_id
         AND (Percent_2.count/Percent_1.count >= (arg_pct/100.0));
    END;
$$ LANGUAGE plpgsql;

-- h) Display the schedule of a route
CREATE OR REPLACE FUNCTION route_schedule_display(arg_route_id int)
RETURNS SETOF Route_Schedule
AS $$
    BEGIN
        RETURN QUERY
            SELECT day, time, train_id
            FROM Route_Schedule
            WHERE route_id = arg_route_id;
    END;
$$ LANGUAGE plpgsql;

-- i) Find the availability of a route at every stop on a specific day and time
CREATE OR REPLACE FUNCTION route_availability(arg_route_id int, arg_date int, arg_time time)
RETURNS SETOF Passes_Thru_SR
AS $$
    BEGIN
        CREATE OR REPLACE VIEW routes_at_day_time AS
            SELECT *
            FROM Route_Schedule
            WHERE route_id=arg_route_id and day=arg_date and time=arg_time;
        CREATE OR REPLACE VIEW stops_availability AS
            SELECT *
            FROM routes_at_day_time NATUrAL JOIN Passes_Thru_SR;
        RETURN QUERY
            SELECT station_id, stops
            FROM stops_availability;
    END;
$$ LANGUAGE plpgsql;

-- 6. Other Operations (Exit)
-- The Exit functionality will be handled by the Java user interface

-- Reservation Cancel Trigger
-- Cancels all reservations if they haven’t ticketed two hours before departure. This trigger uses the CLOCK table
CREATE OR REPLACE FUNCTION check_reservation_cancel()
RETURNS TRIGGER
AS $$
    DECLARE
        reservation_cursor CURSOR FOR
            SELECT reservation_id, route_id, train_id
            FROM Reservation;
        cursor_reservation_id int;
        cursor_route_id int;
        cursor_train_id int;
        res_time time;
        res_day int;
        curr_dow varchar;
    BEGIN
        -- if train_id and route_id match in Reservation and Route_Schedule AND date/time with CLOCK (timestamp) values within 2 hours
        -- if reservation is not in the ticket table (not paid for yet), then CANCEL (if already paid, we don't care)
        -- if all of this, remove entry from Reservation
        -- new is the updated CLOCK -> new.pdate
        OPEN reservation_cursor;
        curr_dow := EXTRACT(isodow FROM (SELECT p_date FROM CLOCK));
        LOOP
            FETCH NEXT FROM reservation_cursor INTO cursor_reservation_id, cursor_route_id, cursor_train_id;
            IF NOT FOUND THEN
                EXIT;
            END IF;
            IF NOT EXISTS(SELECT * FROM Ticket WHERE reservation_id=cursor_reservation_id) THEN
                res_time := (
                    SELECT time
                    FROM Route_Schedule
                    WHERE train_id=cursor_train_id and route_id=cursor_route_id
                );
                res_day := (
                    SELECT day
                    FROM Route_Schedule
                    WHERE train_id=cursor_train_id and route_id=cursor_route_id
                );
                IF curr_dow != res_day THEN
                    CONTINUE;
                END IF; -- logic not perfect, but it will do for now --
                IF EXTRACT(seconds FROM res_time) - EXTRACT(seconds FROM (SELECT p_date FROM CLOCK)) < 120 THEN
                    DELETE FROM Reservation WHERE reservation_id=cursor_reservation_id;
                END IF;
            END IF;
        END LOOP;

    END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS reservation_cancel ON CLOCK;
CREATE TRIGGER reservation_cancel
AFTER UPDATE ON CLOCK
FOR EACH ROW
EXECUTE FUNCTION check_reservation_cancel();

-- Line Disruption Trigger --
CREATE OR REPLACE FUNCTION check_line_disruption()
RETURNS TRIGGER
AS $$
    BEGIN

    END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS line_disruption ON Rail_Line;
CREATE TRIGGER line_disruption
AFTER UPDATE ON Rail_Line
FOR EACH ROW
EXECUTE FUNCTION check_line_disruption();