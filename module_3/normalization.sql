NORMALIZATION TOOL
-- Week 3 | 11 March – 17 March
-- Functional dependency analysis and BCNF decomposition
-- ============================================================
 
/*
  NORMALIZATION ANALYSIS
  ─────────────────────────────────────────────────────────────
  Consider an un-normalized "CAMPUS_RECORD" relation:
 
  CAMPUS_RECORD(
      student_id, student_name, student_email, department_name,
      hod_name, course_code, course_title, credits, faculty_name,
      grade, hostel_block, warden_name
  )
 
  FUNCTIONAL DEPENDENCIES (FDs):
  ───────────────────────────────
  FD1:  student_id   → student_name, student_email, department_name
  FD2:  department_name → hod_name
  FD3:  course_code  → course_title, credits, faculty_name
  FD4:  student_id, course_code → grade
  FD5:  hostel_block → warden_name
  FD6:  student_id   → hostel_block
 
  CANDIDATE KEY: (student_id, course_code)
 
  ─────────────────────────────────────────────────────────────
  1NF CHECK:
    ✓ All attributes are atomic (no multi-valued or composite)
    ✓ Each row is uniquely identifiable by (student_id, course_code)
    Result: Relation is in 1NF
 
  2NF CHECK:
    Partial dependencies exist (violates 2NF):
    - FD1: student_id → student_name, email, dept (partial on key)
    - FD3: course_code → title, credits, faculty (partial on key)
    - FD2: dept → hod (transitive + partial)
    - FD5/6: student_id → hostel_block → warden (transitive + partial)
    Result: NOT in 2NF
 
  3NF CHECK:
    After removing partial dependencies, transitive dependencies remain:
    - department_name → hod_name (non-key → non-key)
    - hostel_block → warden_name (non-key → non-key)
    Result: NOT in 3NF
 
  BCNF CHECK:
    For every non-trivial FD X → Y, X must be a superkey.
    - department_name → hod_name : dept_name is NOT a superkey → VIOLATES BCNF
    - hostel_block → warden_name : hostel_block is NOT a superkey → VIOLATES BCNF
    Result: NOT in BCNF
  ─────────────────────────────────────────────────────────────
 
  BCNF DECOMPOSITION:
  ─────────────────────────────────────────────────────────────
  Step 1: Remove partial FDs (achieve 2NF)
    R1(student_id, student_name, email, department_name, hostel_block)
    R2(course_code, course_title, credits, faculty_name)
    R3(student_id, course_code, grade)           ← fact table
 
  Step 2: Remove transitive FDs in R1 (achieve 3NF/BCNF)
    R1a(student_id, student_name, email, department_name, hostel_block)
    R1b(department_name, hod_name)               ← split out
    R1c(hostel_block, warden_name)               ← split out
 
  FINAL BCNF RELATIONS:
    STUDENT_INFO(student_id, name, email, department_name, hostel_block)
       PK: student_id
    DEPARTMENT(department_name, hod_name)
       PK: department_name
    HOSTEL_INFO(hostel_block, warden_name)
       PK: hostel_block
    COURSE_INFO(course_code, course_title, credits, faculty_name)
       PK: course_code
    STUDENT_COURSE(student_id, course_code, grade)
       PK: (student_id, course_code)
 
  All relations are now in BCNF.
*/
 
-- BCNF Decomposed Tables (illustrative, supplementary to main schema)
CREATE TABLE IF NOT EXISTS NF_DEPARTMENT (
    department_name  VARCHAR(50) PRIMARY KEY,
    hod_name         VARCHAR(100) NOT NULL
);
 
CREATE TABLE IF NOT EXISTS NF_HOSTEL_INFO (
    hostel_block    VARCHAR(10) PRIMARY KEY,
    warden_name     VARCHAR(100)
);
 
CREATE TABLE IF NOT EXISTS NF_STUDENT_INFO (
    student_id      INT PRIMARY KEY,
    student_name    VARCHAR(100)    NOT NULL,
    student_email   VARCHAR(100)    UNIQUE NOT NULL,
    department_name VARCHAR(50),
    hostel_block    VARCHAR(10),
    FOREIGN KEY (department_name) REFERENCES NF_DEPARTMENT(department_name),
    FOREIGN KEY (hostel_block)    REFERENCES NF_HOSTEL_INFO(hostel_block)
);
 
CREATE TABLE IF NOT EXISTS NF_COURSE_INFO (
    course_code     VARCHAR(10) PRIMARY KEY,
    course_title    VARCHAR(150)    NOT NULL,
    credits         INT             NOT NULL,
    faculty_name    VARCHAR(100)
);
 
CREATE TABLE IF NOT EXISTS NF_STUDENT_COURSE (
    student_id      INT         NOT NULL,
    course_code     VARCHAR(10) NOT NULL,
    grade           VARCHAR(2),
    PRIMARY KEY (student_id, course_code),
    FOREIGN KEY (student_id)  REFERENCES NF_STUDENT_INFO(student_id),
    FOREIGN KEY (course_code) REFERENCES NF_COURSE_INFO(course_code)
);
 
-- Populate BCNF tables from the main schema
INSERT IGNORE INTO NF_DEPARTMENT (department_name, hod_name)
SELECT DISTINCT department, CONCAT('Prof. ', department, ' HOD') FROM FACULTY;
 
INSERT IGNORE INTO NF_HOSTEL_INFO (hostel_block, warden_name)
SELECT DISTINCT block_name, warden_name FROM HOSTEL;
 
INSERT IGNORE INTO NF_STUDENT_INFO
SELECT student_id, name, email, department, hostel_block FROM STUDENT;
 
INSERT IGNORE INTO NF_COURSE_INFO
SELECT c.course_code, c.title, c.credits, f.name
FROM COURSE c LEFT JOIN FACULTY f ON c.faculty_id = f.faculty_id;
 
INSERT IGNORE INTO NF_STUDENT_COURSE
SELECT e.student_id, c.course_code, e.grade
FROM ENROLLMENT e JOIN COURSE c ON e.course_id = c.course_id;
 
-- Verification: Reconstruct original relation via joins (lossless decomposition test)
SELECT
    si.student_id,  si.student_name,  si.student_email,
    si.department_name, d.hod_name,
    sc.course_code, ci.course_title,  ci.credits, ci.faculty_name,
    sc.grade,
    si.hostel_block, hi.warden_name
FROM NF_STUDENT_COURSE sc
JOIN NF_STUDENT_INFO si ON sc.student_id  = si.student_id
JOIN NF_DEPARTMENT   d  ON si.department_name = d.department_name
JOIN NF_COURSE_INFO  ci ON sc.course_code  = ci.course_code
JOIN NF_HOSTEL_INFO  hi ON si.hostel_block = hi.hostel_block
ORDER BY si.student_id, sc.course_code;