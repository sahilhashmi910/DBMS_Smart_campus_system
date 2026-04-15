-- ============================================================
--   SMART CAMPUS SYSTEM — COMPLETE SQL PROJECT
--   Covers: Module 1 (Schema), Module 2 (Queries),
--           Module 3 (Normalization), Module 4 (Transactions),
--           Module 5 (Concurrency Control)
-- ============================================================


-- ============================================================
-- MODULE 1: ER MODEL TO SCHEMA CONVERSION
-- Week 1 | 8 Feb – 22 Feb
-- ============================================================

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS EVENT_REGISTRATION;
DROP TABLE IF EXISTS EVENT;
DROP TABLE IF EXISTS ATTENDANCE;
DROP TABLE IF EXISTS CANTEEN_ORDER;
DROP TABLE IF EXISTS CANTEEN;
DROP TABLE IF EXISTS HOSTEL_ALLOCATION;
DROP TABLE IF EXISTS HOSTEL;
DROP TABLE IF EXISTS BOOK_ISSUE;
DROP TABLE IF EXISTS LIBRARY_BOOK;
DROP TABLE IF EXISTS ENROLLMENT;
DROP TABLE IF EXISTS COURSE;
DROP TABLE IF EXISTS FACULTY;
DROP TABLE IF EXISTS STUDENT;

-- ─────────────────────────────────────────────
-- STUDENT
-- ─────────────────────────────────────────────
CREATE TABLE STUDENT (
    student_id      INT PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(100)        NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    department      VARCHAR(50)         NOT NULL,
    year_of_study   INT                 NOT NULL CHECK (year_of_study BETWEEN 1 AND 5),
    hostel_block    VARCHAR(10),
    phone           VARCHAR(15),
    date_of_birth   DATE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────
-- FACULTY
-- ─────────────────────────────────────────────
CREATE TABLE FACULTY (
    faculty_id      INT PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(100)        NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    department      VARCHAR(50)         NOT NULL,
    designation     VARCHAR(50)         NOT NULL,
    phone           VARCHAR(15),
    joining_date    DATE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────
-- COURSE
-- ─────────────────────────────────────────────
CREATE TABLE COURSE (
    course_id       INT PRIMARY KEY AUTO_INCREMENT,
    course_code     VARCHAR(10) UNIQUE  NOT NULL,
    title           VARCHAR(150)        NOT NULL,
    credits         INT                 NOT NULL CHECK (credits BETWEEN 1 AND 6),
    department      VARCHAR(50)         NOT NULL,
    faculty_id      INT,
    semester        VARCHAR(10),
    FOREIGN KEY (faculty_id) REFERENCES FACULTY(faculty_id) ON DELETE SET NULL
);

-- ─────────────────────────────────────────────
-- ENROLLMENT
-- ─────────────────────────────────────────────
CREATE TABLE ENROLLMENT (
    enrollment_id   INT PRIMARY KEY AUTO_INCREMENT,
    student_id      INT         NOT NULL,
    course_id       INT         NOT NULL,
    enrollment_date DATE        NOT NULL DEFAULT (CURDATE()),
    grade           VARCHAR(2),
    status          VARCHAR(20) NOT NULL DEFAULT 'Active'
                        CHECK (status IN ('Active','Completed','Dropped','Withdrawn')),
    UNIQUE KEY uq_enrollment (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES STUDENT(student_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id)  REFERENCES COURSE(course_id)   ON DELETE CASCADE
);

-- ─────────────────────────────────────────────
-- LIBRARY_BOOK
-- ─────────────────────────────────────────────
CREATE TABLE LIBRARY_BOOK (
    book_id         INT PRIMARY KEY AUTO_INCREMENT,
    title           VARCHAR(200)    NOT NULL,
    author          VARCHAR(100)    NOT NULL,
    isbn            VARCHAR(20) UNIQUE,
    category        VARCHAR(50),
    total_copies    INT     NOT NULL DEFAULT 1,
    available_copies INT   NOT NULL DEFAULT 1,
    publisher       VARCHAR(100),
    publish_year    INT,
    CONSTRAINT chk_copies CHECK (available_copies <= total_copies AND available_copies >= 0)
);

-- ─────────────────────────────────────────────
-- BOOK_ISSUE
-- ─────────────────────────────────────────────
CREATE TABLE BOOK_ISSUE (
    issue_id        INT PRIMARY KEY AUTO_INCREMENT,
    student_id      INT         NOT NULL,
    book_id         INT         NOT NULL,
    issue_date      DATE        NOT NULL DEFAULT (CURDATE()),
    due_date        DATE        NOT NULL,
    return_date     DATE,
    fine_amount     DECIMAL(8,2) DEFAULT 0.00,
    issued_by       VARCHAR(50),
    FOREIGN KEY (student_id) REFERENCES STUDENT(student_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id)    REFERENCES LIBRARY_BOOK(book_id) ON DELETE CASCADE
);

-- ─────────────────────────────────────────────
-- HOSTEL
-- ─────────────────────────────────────────────
CREATE TABLE HOSTEL (
    hostel_id       INT PRIMARY KEY AUTO_INCREMENT,
    block_name      VARCHAR(20) UNIQUE  NOT NULL,
    type            VARCHAR(10)         NOT NULL CHECK (type IN ('Boys','Girls')),
    total_rooms     INT                 NOT NULL,
    warden_name     VARCHAR(100),
    warden_phone    VARCHAR(15),
    capacity        INT
);

-- ─────────────────────────────────────────────
-- HOSTEL_ALLOCATION
-- ─────────────────────────────────────────────
CREATE TABLE HOSTEL_ALLOCATION (
    allocation_id   INT PRIMARY KEY AUTO_INCREMENT,
    student_id      INT         NOT NULL UNIQUE,  -- one room per student
    hostel_id       INT         NOT NULL,
    room_number     INT         NOT NULL,
    alloc_date      DATE        NOT NULL DEFAULT (CURDATE()),
    vacate_date     DATE,
    status          VARCHAR(20) NOT NULL DEFAULT 'Active'
                        CHECK (status IN ('Active','Vacated')),
    FOREIGN KEY (student_id) REFERENCES STUDENT(student_id) ON DELETE CASCADE,
    FOREIGN KEY (hostel_id)  REFERENCES HOSTEL(hostel_id)   ON DELETE CASCADE
);

-- ─────────────────────────────────────────────
-- CANTEEN
-- ─────────────────────────────────────────────
CREATE TABLE CANTEEN (
    canteen_id      INT PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(100)    NOT NULL,
    location        VARCHAR(100),
    open_time       TIME,
    close_time      TIME,
    manager_name    VARCHAR(100)
);

-- ─────────────────────────────────────────────
-- CANTEEN_ORDER
-- ─────────────────────────────────────────────
CREATE TABLE CANTEEN_ORDER (
    order_id        INT PRIMARY KEY AUTO_INCREMENT,
    student_id      INT             NOT NULL,
    canteen_id      INT             NOT NULL,
    order_time      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount    DECIMAL(10,2)   NOT NULL CHECK (total_amount >= 0),
    payment_mode    VARCHAR(20)     NOT NULL DEFAULT 'Cash'
                        CHECK (payment_mode IN ('Cash','UPI','Card','Wallet')),
    status          VARCHAR(20)     NOT NULL DEFAULT 'Pending'
                        CHECK (status IN ('Pending','Completed','Cancelled')),
    FOREIGN KEY (student_id)  REFERENCES STUDENT(student_id)  ON DELETE CASCADE,
    FOREIGN KEY (canteen_id)  REFERENCES CANTEEN(canteen_id)  ON DELETE CASCADE
);

-- ─────────────────────────────────────────────
-- ATTENDANCE
-- ─────────────────────────────────────────────
CREATE TABLE ATTENDANCE (
    attendance_id   INT PRIMARY KEY AUTO_INCREMENT,
    student_id      INT         NOT NULL,
    course_id       INT         NOT NULL,
    attendance_date DATE        NOT NULL,
    status          VARCHAR(10) NOT NULL CHECK (status IN ('Present','Absent','Late')),
    UNIQUE KEY uq_attendance (student_id, course_id, attendance_date),
    FOREIGN KEY (student_id) REFERENCES STUDENT(student_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id)  REFERENCES COURSE(course_id)   ON DELETE CASCADE
);

-- ─────────────────────────────────────────────
-- EVENT
-- ─────────────────────────────────────────────
CREATE TABLE EVENT (
    event_id        INT PRIMARY KEY AUTO_INCREMENT,
    title           VARCHAR(200)    NOT NULL,
    description     TEXT,
    event_date      DATETIME        NOT NULL,
    venue           VARCHAR(150),
    organizer_id    INT,
    max_participants INT,
    event_type      VARCHAR(50),
    FOREIGN KEY (organizer_id) REFERENCES FACULTY(faculty_id) ON DELETE SET NULL
);

-- ─────────────────────────────────────────────
-- EVENT_REGISTRATION
-- ─────────────────────────────────────────────
CREATE TABLE EVENT_REGISTRATION (
    reg_id          INT PRIMARY KEY AUTO_INCREMENT,
    student_id      INT         NOT NULL,
    event_id        INT         NOT NULL,
    reg_date        DATE        NOT NULL DEFAULT (CURDATE()),
    participation_status VARCHAR(20) NOT NULL DEFAULT 'Registered'
                        CHECK (participation_status IN ('Registered','Attended','Absent','Cancelled')),
    UNIQUE KEY uq_event_reg (student_id, event_id),
    FOREIGN KEY (student_id) REFERENCES STUDENT(student_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id)   REFERENCES EVENT(event_id)     ON DELETE CASCADE
);


-- ─────────────────────────────────────────────
-- SAMPLE DATA
-- ─────────────────────────────────────────────

INSERT INTO FACULTY (name, email, department, designation, phone, joining_date) VALUES
('Dr. Anita Sharma',  'anita.sharma@campus.edu',  'Computer Science', 'Professor',          '9810011001', '2010-07-15'),
('Prof. Ravi Kumar',  'ravi.kumar@campus.edu',    'Mathematics',      'Associate Professor', '9810011002', '2015-01-20'),
('Dr. Meena Pillai',  'meena.pillai@campus.edu',  'Electronics',      'Assistant Professor', '9810011003', '2018-08-01'),
('Prof. Ajay Singh',  'ajay.singh@campus.edu',    'Computer Science', 'Associate Professor', '9810011004', '2012-06-10'),
('Dr. Priya Nair',    'priya.nair@campus.edu',    'Physics',          'Professor',           '9810011005', '2008-03-25');

INSERT INTO STUDENT (name, email, department, year_of_study, hostel_block, phone, date_of_birth) VALUES
('Rahul Verma',    'rahul.v@campus.edu',    'Computer Science', 3, 'A', '9901001001', '2003-05-12'),
('Sneha Gupta',    'sneha.g@campus.edu',    'Mathematics',      2, 'C', '9901001002', '2004-08-22'),
('Arjun Mehta',    'arjun.m@campus.edu',    'Electronics',      4, 'B', '9901001003', '2002-11-30'),
('Pooja Iyer',     'pooja.i@campus.edu',    'Computer Science', 1, 'D', '9901001004', '2005-03-17'),
('Karan Malhotra', 'karan.ma@campus.edu',   'Physics',          3, 'A', '9901001005', '2003-09-08'),
('Divya Nair',     'divya.n@campus.edu',    'Computer Science', 2, 'C', '9901001006', '2004-01-25'),
('Amit Patel',     'amit.p@campus.edu',     'Mathematics',      4, 'B', '9901001007', '2002-07-14'),
('Sakshi Joshi',   'sakshi.j@campus.edu',   'Electronics',      1, 'D', '9901001008', '2005-06-09'),
('Vikram Rao',     'vikram.r@campus.edu',   'Computer Science', 3, 'A', '9901001009', '2003-12-03'),
('Anjali Singh',   'anjali.s@campus.edu',   'Physics',          2, 'C', '9901001010', '2004-04-18');

INSERT INTO COURSE (course_code, title, credits, department, faculty_id, semester) VALUES
('CS301', 'Database Management Systems',  4, 'Computer Science', 1, 'Odd'),
('CS302', 'Operating Systems',            4, 'Computer Science', 4, 'Even'),
('MA201', 'Discrete Mathematics',         3, 'Mathematics',      2, 'Odd'),
('EC401', 'Digital Signal Processing',    4, 'Electronics',      3, 'Even'),
('PH301', 'Quantum Mechanics',            3, 'Physics',          5, 'Odd'),
('CS401', 'Machine Learning',             4, 'Computer Science', 1, 'Even'),
('MA301', 'Linear Algebra',               3, 'Mathematics',      2, 'Odd');

INSERT INTO ENROLLMENT (student_id, course_id, enrollment_date, grade, status) VALUES
(1,1,'2024-01-10','A','Completed'),(1,2,'2024-01-10','B+','Completed'),
(2,3,'2024-01-12','A+','Completed'),(2,1,'2024-01-12','B','Completed'),
(3,4,'2024-01-11','A','Completed'),(3,2,'2024-01-11','B+','Completed'),
(4,1,'2024-07-15',NULL,'Active'),  (4,6,'2024-07-15',NULL,'Active'),
(5,5,'2024-01-10','A','Completed'),(5,3,'2024-01-10','B','Completed'),
(6,1,'2024-07-15',NULL,'Active'),  (6,2,'2024-07-15',NULL,'Active'),
(7,3,'2024-01-12','A+','Completed'),(7,7,'2024-01-12','A','Completed'),
(8,4,'2024-07-15',NULL,'Active'),  (9,1,'2024-01-10','B+','Completed'),
(9,6,'2024-01-10','A','Completed'),(10,5,'2024-01-12','B+','Completed');

INSERT INTO LIBRARY_BOOK (title, author, isbn, category, total_copies, available_copies, publisher, publish_year) VALUES
('Database System Concepts',      'Silberschatz et al.', '978-0073523323', 'Computer Science', 5, 3, 'McGraw Hill',  2019),
('Introduction to Algorithms',    'Cormen et al.',       '978-0262033848', 'Computer Science', 4, 2, 'MIT Press',    2022),
('Operating System Concepts',     'Silberschatz',        '978-1119320913', 'Computer Science', 3, 1, 'Wiley',        2018),
('Discrete Mathematics',          'Rosen',               '978-0073383095', 'Mathematics',      6, 5, 'McGraw Hill',  2018),
('Signals and Systems',           'Oppenheim',           '978-0138147570', 'Electronics',      3, 2, 'Pearson',      2015),
('Quantum Physics',               'Gasiorowicz',         '978-0471057000', 'Physics',          2, 0, 'Wiley',        2003),
('Machine Learning',              'Tom Mitchell',        '978-0070428072', 'Computer Science', 4, 4, 'McGraw Hill',  1997),
('Linear Algebra Done Right',     'Sheldon Axler',       '978-3030551582', 'Mathematics',      3, 3, 'Springer',     2024);

INSERT INTO BOOK_ISSUE (student_id, book_id, issue_date, due_date, return_date, fine_amount) VALUES
(1, 1, '2024-08-01', '2024-08-15', '2024-08-14', 0.00),
(2, 4, '2024-08-05', '2024-08-19', '2024-08-20', 5.00),
(3, 6, '2024-08-10', '2024-08-24', NULL,          0.00),
(4, 2, '2024-08-12', '2024-08-26', NULL,          0.00),
(5, 5, '2024-07-20', '2024-08-03', '2024-08-10', 35.00),
(6, 3, '2024-08-15', '2024-08-29', NULL,          0.00),
(1, 7, '2024-08-18', '2024-09-01', NULL,          0.00),
(9, 1, '2024-07-30', '2024-08-13', '2024-08-13', 0.00);

INSERT INTO HOSTEL (block_name, type, total_rooms, warden_name, warden_phone, capacity) VALUES
('Block A', 'Boys',  100, 'Mr. Suresh Pandey',  '9800001001', 200),
('Block B', 'Boys',   80, 'Mr. Deepak Sharma',  '9800001002', 160),
('Block C', 'Girls',  90, 'Mrs. Kavita Menon',  '9800001003', 180),
('Block D', 'Girls',  70, 'Mrs. Sunita Reddy',  '9800001004', 140);

INSERT INTO HOSTEL_ALLOCATION (student_id, hostel_id, room_number, alloc_date, status) VALUES
(1,1,101,'2024-07-15','Active'),(3,2,205,'2024-07-15','Active'),
(5,1,108,'2024-07-15','Active'),(7,2,301,'2023-07-15','Active'),
(9,1,114,'2024-07-15','Active'),(2,3,102,'2024-07-15','Active'),
(4,4,205,'2024-07-15','Active'),(6,3,210,'2024-07-15','Active'),
(8,4,115,'2024-07-15','Active'),(10,3,220,'2024-07-15','Active');

INSERT INTO CANTEEN (name, location, open_time, close_time, manager_name) VALUES
('Main Canteen',    'Central Block',  '07:30:00', '21:00:00', 'Mr. Balram Das'),
('Mini Cafeteria',  'Library Wing',   '08:00:00', '18:00:00', 'Ms. Rina Bose'),
('Juice Corner',    'Sports Complex', '10:00:00', '20:00:00', 'Mr. Raju Yadav');

INSERT INTO CANTEEN_ORDER (student_id, canteen_id, order_time, total_amount, payment_mode, status) VALUES
(1,1,'2024-08-19 08:30:00',  85.00, 'UPI',   'Completed'),
(2,1,'2024-08-19 12:15:00', 120.00, 'Cash',  'Completed'),
(3,2,'2024-08-19 14:00:00',  45.00, 'UPI',   'Completed'),
(4,1,'2024-08-20 08:45:00',  95.00, 'Card',  'Completed'),
(5,3,'2024-08-20 11:00:00',  60.00, 'Cash',  'Completed'),
(1,2,'2024-08-20 15:30:00',  30.00, 'UPI',   'Completed'),
(6,1,'2024-08-21 09:00:00', 110.00, 'UPI',   'Completed'),
(7,1,'2024-08-21 12:45:00',  75.00, 'Cash',  'Completed'),
(2,3,'2024-08-21 16:00:00',  50.00, 'Wallet','Completed'),
(8,1,'2024-08-22 08:30:00', 140.00, 'Card',  'Completed');

INSERT INTO ATTENDANCE (student_id, course_id, attendance_date, status) VALUES
(1,1,'2024-08-01','Present'),(1,1,'2024-08-03','Present'),(1,1,'2024-08-06','Absent'),
(1,1,'2024-08-08','Present'),(1,1,'2024-08-10','Late'),
(2,3,'2024-08-01','Present'),(2,3,'2024-08-03','Present'),(2,3,'2024-08-06','Present'),
(2,1,'2024-08-01','Absent'), (2,1,'2024-08-03','Present'),(2,1,'2024-08-06','Present'),
(3,4,'2024-08-01','Present'),(3,4,'2024-08-03','Absent'), (3,4,'2024-08-06','Present'),
(4,1,'2024-08-01','Present'),(4,1,'2024-08-03','Present'),(4,1,'2024-08-06','Present'),
(5,5,'2024-08-01','Present'),(5,5,'2024-08-03','Present'),(5,5,'2024-08-06','Absent'),
(6,1,'2024-08-01','Present'),(6,1,'2024-08-03','Late'),   (6,1,'2024-08-06','Present'),
(9,1,'2024-08-01','Present'),(9,1,'2024-08-03','Present'),(9,1,'2024-08-06','Present');

INSERT INTO EVENT (title, description, event_date, venue, organizer_id, max_participants, event_type) VALUES
('Tech Fest 2024',       'Annual technology festival',        '2024-09-15 09:00:00', 'Auditorium',       1, 500, 'Cultural'),
('Hackathon 2024',       '24-hour coding challenge',          '2024-10-05 10:00:00', 'Computer Lab 1',   4, 100, 'Technical'),
('Science Exhibition',   'Showcase of student projects',      '2024-09-25 11:00:00', 'Exhibition Hall',  3,  50, 'Academic'),
('Sports Day',           'Annual inter-department sports',    '2024-11-10 08:00:00', 'Sports Ground',    5, 300, 'Sports'),
('Workshop on AI',       'Intro to ML and Deep Learning',     '2024-09-20 10:00:00', 'Seminar Hall',     1,  80, 'Workshop');

INSERT INTO EVENT_REGISTRATION (student_id, event_id, reg_date, participation_status) VALUES
(1,1,'2024-09-01','Attended'),(1,2,'2024-09-15','Attended'),(1,5,'2024-09-10','Attended'),
(2,1,'2024-09-02','Attended'),(2,3,'2024-09-12','Attended'),
(3,4,'2024-10-20','Attended'),(3,2,'2024-09-16','Absent'),
(4,1,'2024-09-03','Attended'),(4,5,'2024-09-11','Attended'),
(5,4,'2024-10-25','Registered'),(6,1,'2024-09-04','Attended'),
(6,2,'2024-09-17','Attended'),(7,3,'2024-09-14','Attended'),
(8,4,'2024-10-28','Registered'),(9,1,'2024-09-05','Attended'),
(9,2,'2024-09-18','Attended'),(10,5,'2024-09-12','Attended');



-- Minimum 5 complex SQL queries with joins and aggregates
-- ============================================================
 
-- ─────────────────────────────────────────────
-- Q1: Student Performance Dashboard
-- Multi-join: students, enrollments, courses, attendance
-- Aggregates: AVG, COUNT, GROUP BY with HAVING
-- ─────────────────────────────────────────────
SELECT
    s.student_id,
    s.name                                              AS student_name,
    s.department,
    COUNT(DISTINCT e.course_id)                         AS courses_enrolled,
    COUNT(DISTINCT CASE WHEN e.grade IS NOT NULL
          THEN e.course_id END)                         AS courses_completed,
    ROUND(AVG(CASE e.grade
        WHEN 'A+' THEN 10 WHEN 'A'  THEN 9
        WHEN 'B+' THEN 8  WHEN 'B'  THEN 7
        WHEN 'C+' THEN 6  WHEN 'C'  THEN 5
        ELSE NULL END), 2)                              AS cgpa,
    SUM(CASE WHEN a.status = 'Present' THEN 1
             WHEN a.status = 'Late'    THEN 1 ELSE 0 END) AS classes_attended,
    COUNT(a.attendance_id)                              AS total_classes,
    ROUND(
        100.0 * SUM(CASE WHEN a.status IN ('Present','Late') THEN 1 ELSE 0 END)
        / NULLIF(COUNT(a.attendance_id), 0), 2)        AS attendance_pct
FROM STUDENT s
LEFT JOIN ENROLLMENT e  ON s.student_id = e.student_id
LEFT JOIN ATTENDANCE  a ON s.student_id = a.student_id
GROUP BY s.student_id, s.name, s.department
ORDER BY cgpa DESC NULLS LAST;
 
-- ─────────────────────────────────────────────
-- Q2: Library Activity Report with Overdue Detection
-- Joins: students, book_issue, library_book
-- Aggregates: DATEDIFF, CASE, GROUP BY ROLLUP
-- ─────────────────────────────────────────────
SELECT
    s.name                              AS student_name,
    s.department,
    lb.title                            AS book_title,
    bi.issue_date,
    bi.due_date,
    bi.return_date,
    CASE
        WHEN bi.return_date IS NULL AND bi.due_date < CURDATE()
            THEN DATEDIFF(CURDATE(), bi.due_date)
        WHEN bi.return_date > bi.due_date
            THEN DATEDIFF(bi.return_date, bi.due_date)
        ELSE 0
    END                                 AS overdue_days,
    bi.fine_amount,
    CASE
        WHEN bi.return_date IS NULL AND bi.due_date < CURDATE() THEN 'Overdue'
        WHEN bi.return_date IS NULL THEN 'Issued'
        ELSE 'Returned'
    END                                 AS issue_status
FROM BOOK_ISSUE bi
JOIN STUDENT      s  ON bi.student_id = s.student_id
JOIN LIBRARY_BOOK lb ON bi.book_id    = lb.book_id
ORDER BY overdue_days DESC, bi.issue_date;
 
-- ─────────────────────────────────────────────
-- Q3: Department-wise Academic Statistics
-- Uses subquery, multi-table joins, window functions
-- ─────────────────────────────────────────────
SELECT
    dept_stats.department,
    dept_stats.total_students,
    dept_stats.total_faculty,
    dept_stats.total_courses,
    dept_stats.avg_credits,
    dept_stats.total_enrollments,
    RANK() OVER (ORDER BY dept_stats.avg_gpa DESC) AS dept_rank_by_gpa,
    ROUND(dept_stats.avg_gpa, 2)                   AS avg_dept_gpa
FROM (
    SELECT
        s.department,
        COUNT(DISTINCT s.student_id)                AS total_students,
        COUNT(DISTINCT f.faculty_id)                AS total_faculty,
        COUNT(DISTINCT c.course_id)                 AS total_courses,
        ROUND(AVG(c.credits), 1)                    AS avg_credits,
        COUNT(e.enrollment_id)                      AS total_enrollments,
        AVG(CASE e.grade
            WHEN 'A+' THEN 10 WHEN 'A'  THEN 9
            WHEN 'B+' THEN 8  WHEN 'B'  THEN 7
            WHEN 'C+' THEN 6  WHEN 'C'  THEN 5
            ELSE NULL END)                          AS avg_gpa
    FROM STUDENT s
    LEFT JOIN FACULTY    f ON s.department = f.department
    LEFT JOIN COURSE     c ON s.department = c.department
    LEFT JOIN ENROLLMENT e ON s.student_id = e.student_id
    GROUP BY s.department
) dept_stats
ORDER BY avg_dept_gpa DESC;
 
-- ─────────────────────────────────────────────
-- Q4: Hostel & Canteen Expenditure Analysis
-- Multi-join with aggregates, CASE for spending tiers
-- ─────────────────────────────────────────────
SELECT
    s.student_id,
    s.name,
    h.block_name                        AS hostel_block,
    ha.room_number,
    COUNT(co.order_id)                  AS total_orders,
    ROUND(SUM(co.total_amount), 2)      AS total_canteen_spend,
    ROUND(AVG(co.total_amount), 2)      AS avg_order_value,
    MAX(co.total_amount)                AS largest_order,
    GROUP_CONCAT(DISTINCT co.payment_mode ORDER BY co.payment_mode) AS payment_modes_used,
    CASE
        WHEN SUM(co.total_amount) > 300 THEN 'High Spender'
        WHEN SUM(co.total_amount) > 150 THEN 'Moderate Spender'
        ELSE 'Low Spender'
    END                                 AS spending_category
FROM STUDENT s
JOIN HOSTEL_ALLOCATION ha ON s.student_id = ha.student_id
JOIN HOSTEL            h  ON ha.hostel_id  = h.hostel_id
LEFT JOIN CANTEEN_ORDER co ON s.student_id = co.student_id AND co.status = 'Completed'
GROUP BY s.student_id, s.name, h.block_name, ha.room_number
ORDER BY total_canteen_spend DESC;
 
-- ─────────────────────────────────────────────
-- Q5: Event Participation & Faculty Organizer Summary
-- Three-way join with correlated subquery and HAVING
-- ─────────────────────────────────────────────
SELECT
    f.name                              AS organizer,
    f.department,
    COUNT(DISTINCT ev.event_id)         AS events_organized,
    GROUP_CONCAT(ev.title ORDER BY ev.event_date SEPARATOR ' | ') AS event_titles,
    SUM(ev.max_participants)            AS total_capacity,
    (SELECT COUNT(*)
     FROM EVENT_REGISTRATION er2
     JOIN EVENT ev2 ON er2.event_id = ev2.event_id
     WHERE ev2.organizer_id = f.faculty_id
     AND er2.participation_status = 'Attended') AS total_attended,
    ROUND(
        100.0 * (SELECT COUNT(*)
                 FROM EVENT_REGISTRATION er3
                 JOIN EVENT ev3 ON er3.event_id = ev3.event_id
                 WHERE ev3.organizer_id = f.faculty_id
                 AND er3.participation_status = 'Attended')
        / NULLIF(SUM(ev.max_participants), 0), 1) AS fill_rate_pct
FROM FACULTY f
JOIN EVENT ev ON f.faculty_id = ev.organizer_id
GROUP BY f.faculty_id, f.name, f.department
HAVING COUNT(DISTINCT ev.event_id) >= 1
ORDER BY total_attended DESC;
 
-- ─────────────────────────────────────────────
-- Q6: Comprehensive Student Activity Score (Bonus)
-- Combines all campus systems into one ranking query
-- ─────────────────────────────────────────────
SELECT
    s.student_id,
    s.name,
    s.department,
    s.year_of_study,
    -- Academic score (0-40)
    ROUND(COALESCE(40 * AVG(CASE e.grade
        WHEN 'A+' THEN 10 WHEN 'A' THEN 9 WHEN 'B+' THEN 8
        WHEN 'B'  THEN 7  WHEN 'C+' THEN 6 WHEN 'C' THEN 5
        ELSE 0 END) / 10, 0), 2)        AS academic_score,
    -- Attendance score (0-20)
    ROUND(COALESCE(20 * SUM(CASE WHEN a.status IN ('Present','Late') THEN 1 ELSE 0 END)
        / NULLIF(COUNT(a.attendance_id), 0), 0), 2) AS attendance_score,
    -- Event participation score (0-20)
    COALESCE(ep.events_attended * 4, 0) AS event_score,
    -- Library usage score (0-20)
    COALESCE(LEAST(li.books_issued * 5, 20), 0) AS library_score,
    -- Total campus activity score
    ROUND(
        COALESCE(40 * AVG(CASE e.grade
            WHEN 'A+' THEN 10 WHEN 'A' THEN 9 WHEN 'B+' THEN 8
            WHEN 'B'  THEN 7  WHEN 'C+' THEN 6 WHEN 'C' THEN 5
            ELSE 0 END) / 10, 0)
        + COALESCE(20 * SUM(CASE WHEN a.status IN ('Present','Late') THEN 1 ELSE 0 END)
            / NULLIF(COUNT(a.attendance_id), 0), 0)
        + COALESCE(ep.events_attended * 4, 0)
        + COALESCE(LEAST(li.books_issued * 5, 20), 0), 2) AS total_activity_score
FROM STUDENT s
LEFT JOIN ENROLLMENT e ON s.student_id = e.student_id
LEFT JOIN ATTENDANCE a ON s.student_id = a.student_id
LEFT JOIN (SELECT student_id, COUNT(*) AS events_attended
           FROM EVENT_REGISTRATION
           WHERE participation_status = 'Attended'
           GROUP BY student_id) ep ON s.student_id = ep.student_id
LEFT JOIN (SELECT student_id, COUNT(*) AS books_issued
           FROM BOOK_ISSUE
           GROUP BY student_id) li ON s.student_id = li.student_id
GROUP BY s.student_id, s.name, s.department, s.year_of_study,
         ep.events_attended, li.books_issued
ORDER BY total_activity_score DESC;