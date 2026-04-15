-- TRANSACTION SIMULATOR
-- Week 5 | 1 April – 14 April
-- ACID properties with COMMIT/ROLLBACK demonstrations
-- ============================================================
 
-- ─────────────────────────────────────────────
-- DEMO 1: Atomicity — Book Issue Transaction
-- Either the book is issued AND copies decremented, or neither.
-- ─────────────────────────────────────────────
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS proc_issue_book(
    IN  p_student_id INT,
    IN  p_book_id    INT,
    OUT p_result     VARCHAR(100)
)
BEGIN
    DECLARE v_available INT;
    DECLARE v_already_issued INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: Transaction rolled back due to exception.';
    END;
 
    START TRANSACTION;
 
    -- Atomicity: both operations succeed or both fail
    SELECT available_copies INTO v_available
    FROM LIBRARY_BOOK WHERE book_id = p_book_id FOR UPDATE;
 
    SELECT COUNT(*) INTO v_already_issued
    FROM BOOK_ISSUE
    WHERE student_id = p_student_id AND book_id = p_book_id AND return_date IS NULL;
 
    IF v_available <= 0 THEN
        SET p_result = 'ROLLBACK: No copies available. Transaction aborted.';
        ROLLBACK;
    ELSEIF v_already_issued > 0 THEN
        SET p_result = 'ROLLBACK: Student already has this book. Transaction aborted.';
        ROLLBACK;
    ELSE
        -- Atomic pair: insert record AND decrement copies
        INSERT INTO BOOK_ISSUE (student_id, book_id, issue_date, due_date)
        VALUES (p_student_id, p_book_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY));
 
        UPDATE LIBRARY_BOOK
        SET available_copies = available_copies - 1
        WHERE book_id = p_book_id;
 
        COMMIT;
        SET p_result = CONCAT('COMMIT: Book issued successfully. Due: ',
                              DATE_ADD(CURDATE(), INTERVAL 14 DAY));
    END IF;
END //
DELIMITER ;
 
-- Test Scenario A: Valid issue
CALL proc_issue_book(4, 7, @result);
SELECT @result AS transaction_result;
 
-- Test Scenario B: No copies available (book_id=6 has 0 copies)
CALL proc_issue_book(7, 6, @result);
SELECT @result AS transaction_result;
 
-- ─────────────────────────────────────────────
-- DEMO 2: Consistency — Grade Update with Constraint Check
-- Maintains database consistency rules during updates
-- ─────────────────────────────────────────────
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS proc_update_grade(
    IN  p_student_id   INT,
    IN  p_course_id    INT,
    IN  p_grade        VARCHAR(2),
    OUT p_result       VARCHAR(200)
)
BEGIN
    DECLARE v_valid_grade INT;
    DECLARE v_enrollment_exists INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: Transaction rolled back.';
    END;
 
    START TRANSACTION;
 
    -- Consistency: grade must be valid
    SET v_valid_grade = (p_grade IN ('A+','A','B+','B','C+','C','D','F'));
 
    SELECT COUNT(*) INTO v_enrollment_exists
    FROM ENROLLMENT
    WHERE student_id = p_student_id AND course_id = p_course_id;
 
    IF NOT v_valid_grade THEN
        SET p_result = CONCAT('ROLLBACK: Invalid grade "', p_grade, '". Allowed: A+,A,B+,B,C+,C,D,F');
        ROLLBACK;
    ELSEIF v_enrollment_exists = 0 THEN
        SET p_result = 'ROLLBACK: Enrollment record not found. Cannot update grade.';
        ROLLBACK;
    ELSE
        UPDATE ENROLLMENT
        SET grade = p_grade, status = 'Completed'
        WHERE student_id = p_student_id AND course_id = p_course_id;
 
        COMMIT;
        SET p_result = CONCAT('COMMIT: Grade "', p_grade,
                              '" updated for student ', p_student_id,
                              ', course ', p_course_id);
    END IF;
END //
DELIMITER ;
 
-- Test Scenario A: Valid grade update
CALL proc_update_grade(4, 1, 'A+', @result);
SELECT @result AS transaction_result;
 
-- Test Scenario B: Invalid grade (triggers rollback)
CALL proc_update_grade(6, 2, 'Z', @result);
SELECT @result AS transaction_result;
 
-- ─────────────────────────────────────────────
-- DEMO 3: Isolation — Concurrent Canteen Orders
-- Uses SAVEPOINT to demonstrate partial rollbacks
-- ─────────────────────────────────────────────
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS proc_canteen_order_batch()
BEGIN
    DECLARE v_err INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT before_second_order;
        SET v_err = 1;
        COMMIT;
        SELECT 'PARTIAL ROLLBACK: First order committed; second order rolled back.' AS batch_result;
    END;
 
    START TRANSACTION;
 
    -- First order
    INSERT INTO CANTEEN_ORDER (student_id, canteen_id, total_amount, payment_mode, status)
    VALUES (3, 1, 95.00, 'UPI', 'Completed');
 
    SAVEPOINT before_second_order;
 
    -- Second order (simulating a failure via bad student_id)
    INSERT INTO CANTEEN_ORDER (student_id, canteen_id, total_amount, payment_mode, status)
    VALUES (9999, 1, 50.00, 'Cash', 'Completed');  -- FK violation triggers handler
 
    IF v_err = 0 THEN
        COMMIT;
        SELECT 'COMMIT: Both canteen orders processed successfully.' AS batch_result;
    END IF;
END //
DELIMITER ;
 
CALL proc_canteen_order_batch();
 
-- ─────────────────────────────────────────────
-- DEMO 4: Durability — Hostel Reallocation
-- Shows that committed data survives system restart
-- ─────────────────────────────────────────────
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS proc_reallocate_hostel(
    IN  p_student_id    INT,
    IN  p_new_hostel_id INT,
    IN  p_new_room      INT,
    OUT p_result        VARCHAR(200)
)
BEGIN
    DECLARE v_current_alloc INT;
    DECLARE v_room_taken INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: Reallocation failed. Transaction rolled back.';
    END;
 
    START TRANSACTION;
 
    SELECT COUNT(*) INTO v_current_alloc
    FROM HOSTEL_ALLOCATION WHERE student_id = p_student_id;
 
    SELECT COUNT(*) INTO v_room_taken
    FROM HOSTEL_ALLOCATION
    WHERE hostel_id = p_new_hostel_id AND room_number = p_new_room AND status = 'Active';
 
    IF v_room_taken > 0 THEN
        SET p_result = 'ROLLBACK: Room already occupied. Reallocation aborted.';
        ROLLBACK;
    ELSEIF v_current_alloc = 0 THEN
        -- Fresh allocation
        INSERT INTO HOSTEL_ALLOCATION (student_id, hostel_id, room_number, alloc_date, status)
        VALUES (p_student_id, p_new_hostel_id, p_new_room, CURDATE(), 'Active');
        COMMIT;
        SET p_result = CONCAT('COMMIT: New allocation — Room ', p_new_room,
                              ' in Hostel ID ', p_new_hostel_id);
    ELSE
        -- Update existing (Durability: persisted on commit)
        UPDATE HOSTEL_ALLOCATION
        SET hostel_id   = p_new_hostel_id,
            room_number = p_new_room,
            alloc_date  = CURDATE()
        WHERE student_id = p_student_id AND status = 'Active';
 
        COMMIT;  -- After COMMIT, data is durable (written to disk/WAL)
        SET p_result = CONCAT('COMMIT (Durable): Student ', p_student_id,
                              ' reallocated to Room ', p_new_room,
                              ', Hostel ', p_new_hostel_id,
                              '. Change is permanent.');
    END IF;
END //
DELIMITER ;
 
CALL proc_reallocate_hostel(1, 2, 301, @result);
SELECT @result AS transaction_result;
 
-- Room taken scenario (triggers rollback)
CALL proc_reallocate_hostel(3, 1, 101, @result);
SELECT @result AS transaction_result;
 
 
-- ============================================================
-- MODULE 5: CONCURRENCY CONTROL PROTOTYPE
-- Week 6 | 15 April – 22 April
-- Lock-based concurrency with WAIT / NOWAIT scenarios
-- ============================================================
 
-- ─────────────────────────────────────────────
-- DEMO 1: Optimistic Locking with Version Counter
-- Prevents lost-update anomaly without explicit locks
-- ─────────────────────────────────────────────
ALTER TABLE LIBRARY_BOOK ADD COLUMN IF NOT EXISTS version_no INT DEFAULT 0;
 
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS proc_optimistic_update_copies(
    IN  p_book_id  INT,
    IN  p_version  INT,
    IN  p_delta    INT,
    OUT p_result   VARCHAR(200)
)
BEGIN
    DECLARE v_rows_affected INT;
 
    START TRANSACTION;
 
    -- Update only if version matches (optimistic check)
    UPDATE LIBRARY_BOOK
    SET available_copies = available_copies + p_delta,
        version_no       = version_no + 1
    WHERE book_id = p_book_id
      AND version_no  = p_version
      AND (available_copies + p_delta) >= 0
      AND (available_copies + p_delta) <= total_copies;
 
    SET v_rows_affected = ROW_COUNT();
 
    IF v_rows_affected = 0 THEN
        ROLLBACK;
        SET p_result = 'ROLLBACK (Optimistic Lock): Version conflict or constraint violation. Retry required.';
    ELSE
        COMMIT;
        SET p_result = CONCAT('COMMIT: Book ', p_book_id,
                              ' copies updated by ', p_delta,
                              '. New version: ', p_version + 1);
    END IF;
END //
DELIMITER ;
 
-- Scenario A: Correct version → COMMIT
CALL proc_optimistic_update_copies(1, 0, -1, @result);
SELECT @result AS lock_result;
 
-- Scenario B: Stale version (concurrent update already incremented it) → ROLLBACK
CALL proc_optimistic_update_copies(1, 0, -1, @result);
SELECT @result AS lock_result;
 
-- ─────────────────────────────────────────────
-- DEMO 2: Pessimistic Locking — SELECT ... FOR UPDATE (WAIT)
-- Transaction T1 acquires lock; T2 waits until T1 completes
-- ─────────────────────────────────────────────
-- Session 1 (T1): Acquires exclusive lock — run in first connection
-- START TRANSACTION;
-- SELECT * FROM LIBRARY_BOOK WHERE book_id = 2 FOR UPDATE;
-- /* T1 holds the lock — T2 will WAIT */
-- UPDATE LIBRARY_BOOK SET available_copies = available_copies - 1 WHERE book_id = 2;
-- COMMIT;  /* Lock released; T2 proceeds */
 
-- Session 2 (T2): Waits for T1 to release lock — run concurrently
-- START TRANSACTION;
-- SELECT * FROM LIBRARY_BOOK WHERE book_id = 2 FOR UPDATE;  /* WAITS here */
-- UPDATE LIBRARY_BOOK SET available_copies = available_copies - 1 WHERE book_id = 2;
-- COMMIT;
 
-- ─────────────────────────────────────────────
-- DEMO 3: NOWAIT — Fail fast instead of waiting
-- Useful for real-time kiosk / booking systems
-- ─────────────────────────────────────────────
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS proc_nowait_book_issue(
    IN  p_student_id INT,
    IN  p_book_id    INT,
    OUT p_result     VARCHAR(200)
)
BEGIN
    DECLARE v_copies INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'NOWAIT: Resource locked by another transaction. Please retry shortly.';
    END;
 
    START TRANSACTION;
 
    -- NOWAIT: immediately errors if another transaction holds the lock
    SELECT available_copies INTO v_copies
    FROM LIBRARY_BOOK WHERE book_id = p_book_id FOR UPDATE NOWAIT;
 
    IF v_copies <= 0 THEN
        ROLLBACK;
        SET p_result = 'ROLLBACK: No copies available.';
    ELSE
        INSERT INTO BOOK_ISSUE (student_id, book_id, issue_date, due_date)
        VALUES (p_student_id, p_book_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY));
 
        UPDATE LIBRARY_BOOK
        SET available_copies = available_copies - 1
        WHERE book_id = p_book_id;
 
        COMMIT;
        SET p_result = CONCAT('COMMIT (NOWAIT): Book ', p_book_id,
                              ' issued instantly to student ', p_student_id);
    END IF;
END //
DELIMITER ;
 
CALL proc_nowait_book_issue(5, 7, @result);
SELECT @result AS lock_result;
 
-- ─────────────────────────────────────────────
-- DEMO 4: Deadlock Prevention — Consistent Lock Ordering
-- Always acquire locks in the same order to prevent deadlock
-- ─────────────────────────────────────────────
/*
  DEADLOCK SCENARIO (what NOT to do):
    T1: LOCK book_id=1, then book_id=2
    T2: LOCK book_id=2, then book_id=1  ← circular wait → deadlock
 
  PREVENTION: Always acquire locks in ascending book_id order
*/
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS proc_transfer_book_lock(
    IN  p_from_student INT,
    IN  p_to_student   INT,
    IN  p_book_id      INT,
    OUT p_result       VARCHAR(200)
)
BEGIN
    DECLARE v_issue_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'DEADLOCK or ERROR: Transaction rolled back. MySQL auto-resolves deadlocks by aborting one transaction.';
    END;
 
    START TRANSACTION;
 
    -- Lock in consistent order (by book_id, then student_id ascending)
    SELECT issue_id INTO v_issue_id
    FROM BOOK_ISSUE
    WHERE student_id = p_from_student AND book_id = p_book_id AND return_date IS NULL
    FOR UPDATE;
 
    IF v_issue_id IS NULL THEN
        ROLLBACK;
        SET p_result = 'ROLLBACK: No active issue found for transfer.';
    ELSE
        -- Mark original issue as returned
        UPDATE BOOK_ISSUE SET return_date = CURDATE()
        WHERE issue_id = v_issue_id;
 
        -- Create new issue for receiving student
        INSERT INTO BOOK_ISSUE (student_id, book_id, issue_date, due_date)
        VALUES (p_to_student, p_book_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY));
 
        COMMIT;
        SET p_result = CONCAT('COMMIT: Book ', p_book_id,
                              ' transferred from student ', p_from_student,
                              ' to student ', p_to_student);
    END IF;
END //
DELIMITER ;
 
CALL proc_transfer_book_lock(1, 5, 1, @result);
SELECT @result AS lock_result;
 
-- ─────────────────────────────────────────────
-- DEMO 5: Two-Phase Locking (2PL) Simulation
-- Growing phase: acquire all locks; Shrinking phase: release all
-- ─────────────────────────────────────────────
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS proc_2pl_enrollment(
    IN  p_student_id INT,
    IN  p_course_id  INT,
    OUT p_result     VARCHAR(200)
)
BEGIN
    DECLARE v_seat_count INT;
    DECLARE v_already_enrolled INT;
 
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: 2PL Transaction aborted.';
    END;
 
    -- GROWING PHASE: acquire all locks upfront
    START TRANSACTION;
 
    -- Lock 1: student record
    SELECT student_id FROM STUDENT WHERE student_id = p_student_id FOR UPDATE;
 
    -- Lock 2: course record (check capacity via enrollment count)
    SELECT COUNT(*) INTO v_seat_count
    FROM ENROLLMENT WHERE course_id = p_course_id FOR UPDATE;
 
    -- Lock 3: check existing enrollment
    SELECT COUNT(*) INTO v_already_enrolled
    FROM ENROLLMENT WHERE student_id = p_student_id AND course_id = p_course_id;
 
    -- Business logic (all locks held — GROWING phase complete)
    IF v_already_enrolled > 0 THEN
        SET p_result = 'ROLLBACK: Student already enrolled in this course.';
        ROLLBACK;   -- SHRINKING PHASE: release all locks
    ELSEIF v_seat_count >= 60 THEN
        SET p_result = 'ROLLBACK: Course is full (max 60 students).';
        ROLLBACK;   -- SHRINKING PHASE
    ELSE
        INSERT INTO ENROLLMENT (student_id, course_id, enrollment_date, status)
        VALUES (p_student_id, p_course_id, CURDATE(), 'Active');
 
        COMMIT;     -- SHRINKING PHASE: all locks released on commit
        SET p_result = CONCAT('COMMIT (2PL): Student ', p_student_id,
                              ' enrolled in Course ', p_course_id,
                              '. All locks released.');
    END IF;
END //
DELIMITER ;
 
CALL proc_2pl_enrollment(10, 6, @result);
SELECT @result AS lock_result;
 
-- Already enrolled → triggers rollback
CALL proc_2pl_enrollment(1, 1, @result);
SELECT @result AS lock_result;
 
 
-- ─────────────────────────────────────────────
-- USEFUL DIAGNOSTIC QUERIES (run during demos)
-- ─────────────────────────────────────────────
 
-- Check currently active transactions
SELECT * FROM information_schema.INNODB_TRX;
 
-- Check active locks
SELECT * FROM performance_schema.data_locks
WHERE LOCK_STATUS = 'WAITING';
 
-- Check lock waits
SELECT
    r.trx_id                waiting_trx_id,
    r.trx_mysql_thread_id   waiting_thread,
    r.trx_query             waiting_query,
    b.trx_id                blocking_trx_id,
    b.trx_mysql_thread_id   blocking_thread,
    b.trx_query             blocking_query
FROM information_schema.INNODB_LOCK_WAITS w
JOIN information_schema.INNODB_TRX        b ON b.trx_id = w.blocking_trx_id
JOIN information_schema.INNODB_TRX        r ON r.trx_id = w.requesting_trx_id;