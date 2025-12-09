drop database if exists salon_app;
create database if not exists salon_app;

use salon_app;

/*
 * UPDATED DEC 1, 2025 by Melody
 */

/*
 * Users sign up on website and are later split into different roles:
 * Customers, Business, Employee, or Admin.
 * Primary Key: uid (user_id)
 */
create table if not exists users (
	uid int auto_increment primary key,
	first_name varchar(128) not null,
	last_name varchar (128) not null,
	phone varchar(11),
    last_active timestamp default current_timestamp() on update current_timestamp(),
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp()
);

/*
 * Authentication Table: stores sensitive information 
 * to authenticate users signed up.
 * hash used to protect sensitive password information (64hex characters)
 * salt added to hash for extra security (random salts stored as hexadecimal)
 * Primary Key: uid (user_id)
 * Foreign Key: uid(user_id [from users])
 */
create table if not exists authenticate(
    uid int not null,
    email varchar(255) not null,
    pw_hash char(64) not null,
    salt char(32) not null, 
    created_at timestamp default current_timestamp(),
    updated_at timestamp default current_timestamp() on update current_timestamp(),
    constraint pk_authenticate primary key(uid,email),
    foreign key(uid) references users(uid) on delete cascade
);

/*
 * The different roles a user can be: Customer, Business Owner, Employee, or Admin.
 * Primary Key: rid (role_id)
 */
create table if not exists roles (
	rid int auto_increment primary key,
	name varchar(128),
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp()
);

/*
 * Insert customer, business, employee, and admin roles into the roles table
 */
insert into roles (name)
values
	("customer"),
	("business"),
	("employee"),
	("admin");

/*
 * Table that keeps track of the role of every signed up user of the site.
 * Primary Key: uid (user_id)
 * Foreign Keys: rid (role_id [from roles]), uid(user_id[from users])
 */
create table if not exists users_roles (
	uid int not null,
	rid int not null,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	primary key (uid, rid),
	foreign key (uid) references users(uid) on delete cascade,
	foreign key (rid) references roles(rid) on delete cascade
);

/*
 * Table of industries customers can select from for demographics
 * Primary Key: industry_id
 */
create table if not exists industries (
    ind_id int auto_increment primary key,
    name varchar(128) not null unique,
    created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp()
);

/*
 * Customer information recorded into database. Each customer has unique identification.
 * Primary Key: cid (customer_id)
 * Foreign Key: uid (user_id [from users])
 */
create table if not exists customers (
	cid int auto_increment not null,
	uid int not null,
    birthdate date default null,
    gender enum("male", "female", "nonbinary", "other") default null,
    ind_id int default null,
    income decimal(11,2) default null,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	constraint pk_cust primary key (cid, uid),
	foreign key (uid) references users(uid) on delete cascade,
    foreign key (ind_id) references industries(ind_id) on delete set null
);

/*
 * track what type of emails each user wants to receive
 */
create table if not exists email_subscription (
    cid int primary key,
	promotion bool default true,
	appointment bool default true,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (cid) references customers(cid) on delete cascade
);

/*
 * Address of the Businesses Signed Up
 * Primary key: aid(address_id)
 */
create table if not exists addresses (
	aid int auto_increment primary key,
	street varchar(255),
	city varchar(255),
	state varchar(255),
	country varchar(255),
	zip_code varchar(255),
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp()
);

/*
 * Information of Signed Up Businesses Recorded
 * Keep track if Business still opened or not (status)
 * Primary Keys: bid (business_id), uid(user_id)
 * Foreign Keys: uid (user_id[from users]), aid(address_id[from addresses])
 */
create table if not exists business (
	bid int auto_increment primary key,
	uid int not null,
	name varchar(255) not null unique,
	aid int not null,
    year_est int default null,
    deposit_rate decimal(4,3) default 0.000,
	status bool default false,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
    constraint ck_deposit_rate check (deposit_rate < 1.000),
	foreign key (uid) references users(uid) on delete cascade,
	foreign key (aid) references addresses(aid)
);

/*
 * Hours of Operation for salons
 */
create table if not exists hours_of_operation (
	id int auto_increment primary key,
	bid int not null,
	day enum ('sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'),
	open_time time,
	close_time time,
	is_closed bool default false,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	constraint ck_open_and_close check ((open_time is null and close_time is null) or
		(open_time is not null and close_time is not null)),
	constraint ck_closed_logic check (open_time < close_time or is_closed=true),
	foreign key (bid) references business(bid),
	unique key business_day (bid, day)
);

/*
 * Information stored of every worker for each business on record.
 * Primary Keys: eid(employee_id), uid(user_id)
 * Foreign Keys: bid(business_id), uid(user_id)
 */
create table if not exists employee (
	eid int auto_increment primary key,
	uid int not null,
	bid int,
	bio text,
	profile_picture longblob,
	approved bool default false,
    start_year int default null,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (uid) references users(uid) on delete cascade,
	foreign key (bid) references business(bid) on delete set null
);

/*
 * Recording categories that offered services can fall under.
 */
create table if not exists service_categories(
    cat_id int auto_increment primary key,
    name varchar(50) not null,
    created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp()
);

/*
 * Recording of services
 */
create table if not exists services(
    sid int auto_increment primary key,
    bid int,
    name varchar(50) not null,
    cat_id int not null,
    price decimal (6,2),
    duration int, 																	# time service takes
    description varchar(255),
    created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
    foreign key (cat_id) references service_categories(cat_id) on delete cascade,
    foreign key (bid) references business(bid) on delete cascade
);

/*
 * Recording what specific departments that employees can specialize in.
 * Primary Keys: eid(employee_id), exp_id(expertise_id)
 * Foreign Keys: eid(employee_id [from employee]),
 * exp_id(expertise_id[from expertise])
 */
create table if not exists employee_services(
    eid int not null,
    sid int not null,
    created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
    foreign key (eid) references employee(eid) on delete cascade,
    foreign key (sid) references services(sid) on delete cascade
);

/*
 * Keeps record of the scheduled time each employee works
 * Primary Key: sched_id(schedule_id)
 * Foreign Key: eid(employee_id [from employee])
 */
create table if not exists schedule (
    sched_id int auto_increment primary key,
    eid int not null,
	day enum ('sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'),
    start_time time,
    finish_time time,
    created_at timestamp default current_timestamp(),
    updated_at datetime default current_timestamp() on update current_timestamp(),
    foreign key (eid) references employee(eid) on delete cascade
);

/*
 * Stores pictures of employee work, like a portfolio
 */
create table if not exists employee_work_pictures (
	id int auto_increment primary key,
	eid int not null,
	picture longblob,
	active bool default true,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (eid) references employee(eid) on delete cascade
);

/*
 * Records appointments made by customers for each business and for which employee
 */
create table if not exists appointments (
	aid int auto_increment primary key,
	cid int,
	eid int,
	bid int,
	sid int,
	status enum('upcoming', 'pending_payment', 'completed', 'rescheduled', 'cancelled', 'no_show') default 'upcoming',
	start_time timestamp not null,
	expected_end_time timestamp not null,
	end_time timestamp on update current_timestamp(),
	before_image longblob,
	after_image longblob,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (cid) references customers(cid) on delete set null,
	foreign key (eid) references employee(eid) on delete set null,
	foreign key (bid) references business(bid) on delete set null,
	foreign key (sid) references services(sid) on delete set null
);

/*
 *	Records notes for an appointment by all roles.
 */
create table if not exists appointment_notes (
	note_id int auto_increment primary key,
	aid int not null,
	author_uid int,
	author_role varchar(50) not null,
	note_text text not null,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (aid) references appointments(aid) on delete cascade,
	foreign key (author_uid) references users(uid) on delete set null
);

/*
 * Records number of loyalty points per dollar salons use for loyalty programs.
 */
create table if not exists loyalty_points (
	bid int primary key,
	pts_value decimal(10,2) default 1,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (bid) references business(bid) on delete cascade
);

/*
 * each row is a loyalty program a business has implemented; each program has a unique id (lprog_id)
 * foreign key links to business (bid)
 * indication for what type of various loyalty programs are possible: Buy 1 Get 1 Free ("BOGO"), points accumulation, money spent on a business' services
 * or products, amount of visits to the salon.
 * The number at which a reward for a program is met (threshold). For example, after 10 appointments, client gets a free one.
 */
create table if not exists loyalty_programs (
	lprog_id int auto_increment primary key,
	bid int not null,
	appts_thresh bool default false,
	pdct_thresh bool default false,
	price_thresh bool default false,
	points_thresh bool default false,
	threshold int not null,
	description text,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (bid) references business(bid) on delete cascade
);

/*
 * each row is a promotion a business has implemented
 * how long does the promo last (start_date, end_date)
 * does it take on a regular basis (is_recurring)
 * what day(s) of the week would it regularly occur (recurr_days)
 * when does the promo start and end that day (start_time, end_time)
 */
create table if not exists promotions (
	promo_id int auto_increment primary key,
	lprog_id int not null,
	title varchar(128),
	start_date date not null,
	end_date date not null,
	is_recurring bool default false,
	recurr_days varchar(255) null,
	start_time time null,
	end_time time null,
	description text,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (lprog_id) references loyalty_programs(lprog_id) on delete cascade
);

/*
 * track different types of rewards for particular business' loyalty program.
 * which type of Loyalty Program is it corresponding to the programs table above
 * value of reward specifying the value of reward. 10 percent off, 1 free appointment, etc. (rwd_value)
 * foreign keys to loyalty_programs table and business table (lprog_id and bid, respectively.)
 */
create table if not exists rewards(
	rwd_id int auto_increment primary key,
	bid int not null,
	lprog_id int not null,
	is_appt bool default false,
	is_product bool default false,
	is_price bool default false,
	is_points bool default false,
	is_discount bool default false,
	rwd_value decimal(5,2),
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (bid) references business(bid) on delete cascade,
	foreign key (lprog_id) references loyalty_programs(lprog_id) on delete cascade
);

/*
 * Tracking the loyalty points and thresholds for savings for each customer of a business
 */
create table if not exists customer_loyalty_points(
	cid int not null,
	bid int not null,
	pts_balance decimal(10,2),
	appt_complete int,
	prod_purchased int,
	amount_spent decimal(10,2),
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	primary key (cid,bid),
	foreign key (cid) references customers(cid) on delete cascade,
    foreign key (bid) references business (bid) on delete cascade
);

/*
 * products each business sells with their stock
 * image: keeps track of images and stores in db as well
 */
create table if not exists products (
	pid int auto_increment primary key,												# primary key
	name varchar(255),																# name of product
	bid int not null,																# business selling product (foreign key business)
	price decimal(5,2),																# unit price of product
	stock int default 0,
	image LONGBLOB,																	# stock of product defaults to 0
	description text,																# description of product
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (bid) references business(bid) on delete cascade
);

/*
 * stores individual cart item with amount of each product being purchased
 * cid instead of uid because only customers use carts
 */
create table if not exists cart (
	cart_id int auto_increment primary key,  										# primary key
	pid int not null, 																# product customer is buying (product is unique to business) (foreign key products pid)
	amount int default 1,															# how much of a product customer wants
	cid int not null, 																# who is buying product (foreign key users uid)
	bid int not null,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	unique key (cid,pid),   														# needs to be unique for cart adding logic
	foreign key (pid) references products(pid) on delete cascade,
	foreign key (cid) references customers(cid) on delete cascade
);

/*
 * store user payment methods
 */
create table if not exists payment_information (
	id int auto_increment primary key,
	uid int not null,
	payment_type enum('visa','mastercard','discover','american express','debit'),
	cardholder_name varchar(128) not null,
	card_number varchar(128) not null,
	cvv varchar(4) not null,
	exp_month tinyint not null,
	exp_year smallint not null,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (uid) references users(uid) on delete cascade
);

/*
 * track appointment and product transactions
 */
create table if not exists transactions (
    trans_id int auto_increment primary key,
    cid int,
    bid int not null,
    aid int,
    amount decimal(10,2) not null,
    payment_method_id int,
    created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
    foreign key (cid) references customers(cid) on delete set null,
    foreign key (bid) references business(bid),
    foreign key (aid) references appointments(aid),
    foreign key (payment_method_id) references payment_information(id) on delete set null
);

/*
 * Lists products involved in a transaction and the amount of each product purchased
 */
create table if not exists transactions_products (
	trans_id int not null,
	pid int,
	amount int not null,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (trans_id) references transactions(trans_id) on delete cascade,
	foreign key (pid) references products(pid) on delete set null
);

/*
 * track loyalty program transactions made by customers
 */
create table if not exists loyalty_transactions (
	lt_id int auto_increment primary key,											# primary key
	cid int not null,																# customer that made transaction (foreign key customers cid)
	trans_id int not null,
	lprog_id int not null,															# loyalty program that was used for transaction (foreign key loyalty_programs lid)
	val_earned decimal(10,2) default 0,
	val_redeemed decimal(10,2) default 0,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (cid) references customers(cid) on delete cascade,
	foreign key (trans_id) references transactions(trans_id) on delete cascade,
	foreign key (lprog_id) references loyalty_programs(lprog_id) on delete cascade
);

/*
 * MODIFIED: Keeps track of all reviews left by clients on salons/workers; primary key rvw_id (review id) for each unique review record, 
 * with foreign keys linking back to the customer who gave the review, and the business or worker being reviewed (cid, bid, and eid, respectively).
 * rating that runs from 1 to 5 (indicating stars)
 */
create table if not exists reviews (
	rvw_id int auto_increment primary key,
	cid int not null,
	bid int,
	eid int,
	rating int not null check(rating between 1 and 5),
	comment TEXT,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	constraint ck_rev_about check (eid is not null or bid is not null),
	foreign key (cid) references customers(cid) on delete cascade,
	foreign key (bid) references business(bid) on delete cascade,
	foreign key (eid) references employee(eid) on delete cascade
);

/*
 * Replies to review: has its own unique reply id (rply_id)
 * any user can reply to a review (uid recorded), including the Owner or even workers.
 * foreign key links to reviews table's rvw_id, indicating that it is indeed a reply.
 */
create table if not exists review_replies (
	rply_id int auto_increment primary key,
	rvw_id int not null,
	uid int not null,
	comment TEXT,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (uid) references users(uid) on delete cascade,
	foreign key (rvw_id) references reviews(rvw_id) on delete cascade
);

/*
 * Table to save favorite businesses for customers
 */
create table if not exists saved_business (
	id int auto_increment primary key,
	cid int not null,
	bid int not null,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (cid) references customers(cid) on delete cascade,
	foreign key (bid) references business(bid) on delete cascade
);

/*
 * Table to save favorite employees and businesses for customers
 */
create table if not exists saved_employee (
	id int auto_increment primary key,
	cid int not null,
	eid int not null,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (cid) references customers(cid) on delete cascade,
	foreign key (eid) references employee(eid) on delete cascade
);

/*
 * Monthly new users tracking table
 */
create table if not exists new_users_monthly (
	new_users_id int auto_increment primary key,
	year int not null,
	month int not null,
	new_users_count int not null,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	unique key (year, month)
);

/*
 * Monthly active users tracking table
 */
create table if not exists active_users_monthly(
	active_users_id int auto_increment primary key,
	year int not null,
	month int not null,
	active_count int not null,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	unique key (year, month)
);

/*
 * Table to track customer visit history to businesses
 */
create table if not exists visit_history (
	history_id int auto_increment primary key,
	cid int not null,
	bid int not null,
	salon_views int default 0,
	product_views int default 0,
	last_visit timestamp default current_timestamp() on update current_timestamp(),
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	foreign key (cid) references customers(cid) on delete cascade,
	foreign key (bid) references business(bid) on delete cascade,
	unique key (cid, bid)
);

/*
 * Table to track monthly salon revenue
 */
create table if not exists monthly_revenue (
	rev_id int auto_increment primary key,
	bid int not null,
	year int not null,
	month int not null,
	revenue int not null,
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp(),
	unique key (bid, year, month),
	foreign key (bid) references business(bid) on delete cascade
);

/*
 * I have no clue what this table is for
 */
create table if not exists service_time (
	id int auto_increment primary key,
	start_time timestamp default current_timestamp(),
	created_at timestamp default current_timestamp(),
	updated_at datetime default current_timestamp() on update current_timestamp()
);

/*
 * track changes made to tables
 */
create table if not exists audit (
	id int auto_increment primary key,												# primary key
	table_name varchar(128) not null,												# table that was changed
	record_id int not null,															# record of table that was changed
	action enum('insert', 'update', 'delete') not null,								# what type of change
	old_data json,																	# old data
	new_data json,																	# new data
	changed_at timestamp default current_timestamp(),								# When was change made
	changed_by varchar(128)
);
