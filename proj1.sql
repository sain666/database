------------------------------------------------------
-- COMP9311 24T1 Project 1 
-- SQL and PL/pgSQL 
-- Template
-- Name:
-- zID:
------------------------------------------------------

-- Q1:
create or replace view Q1(subject_code)
as
SELECT code 
FROM subjects 
WHERE code LIKE '____7%' 
AND offeredby IN (
    SELECT id 
    FROM orgunits 
    WHERE longname LIKE '%Information%' 
    AND utype = (select id from orgunit_types where name = 'School')
);

-- Q2:
CREATE OR REPLACE VIEW a(course_id) AS 
SELECT course
FROM classes
WHERE ctype IN (select id from class_types where name in ('Lecture','Laboratory'))
group by course
having count(distinct ctype) = 2
EXCEPT
SELECT course
FROM classes
WHERE ctype NOT IN (select id from class_types where name in ('Lecture','Laboratory'));

create or replace view Q2(course_id) as
select course_id from a
EXCEPT
SELECT id
FROM courses
WHERE subject not in (select id from subjects where code like 'COMP%');

-- Q3:
create or replace view a1(id) as
select id
from courses
where semester in (
select id
from semesters
where year > 2007 and year < 2013
);

create or replace view a2(id) as
select course
from course_staff
where staff in 
(select id
from people
where title = 'Prof')
group by course
having count(staff) > 1;

create or replace view Q3(unsw_id) as
select unswid from people
where cast(unswid as text) like '320%'
and id in (
  select student from course_enrolments
  where course in (select * from a1)
  and course in (select * from a2)
  group by student
  having count(course) > 4
);

-- Q4:
create or replace view a3(id) as
select id
from courses
where semester in (
select id
from semesters
where year = 2012
);

create or replace view a4(course, mark) as
SELECT course, ROUND(AVG(mark), 2)
FROM course_enrolments
WHERE course IN (SELECT id FROM a3)
AND grade IN ('DN', 'HD')
GROUP BY course;

create or replace view b(id) as
select id
from orgunits
where utype = (
  select id
  from orgunit_types
  where name='Faculty'
);

create or replace view b1(course, mark, offeredby, semester) as
SELECT a.course, a.mark, s.offeredby, c.semester
FROM a4 a
JOIN courses c ON c.id = a.course
JOIN subjects s ON s.id = c.subject
WHERE s.offeredby IN (SELECT id FROM b);

create or replace view Q4(course_id, avg_mark) as
SELECT b1.course, b1.mark
FROM b1
JOIN (
    SELECT offeredby, semester, MAX(mark) AS max_mark
    FROM b1
    GROUP BY offeredby, semester
) AS max_marks ON b1.offeredby = max_marks.offeredby 
               AND b1.semester = max_marks.semester 
               AND b1.mark = max_marks.max_mark;

-- Q5:
create or replace view a5(id) as
select id
from courses
where semester in (
select id
from semesters
where year > 2004 and year < 2016
);

create or replace view a6(id) as
select course
from course_staff
where staff in 
(select id
from people
where title = 'Prof')
group by course
having count(staff) > 1;

create or replace view a7(id) as
select course
from course_enrolments
where course in (select * from a5)
and course in (select * from a6)
group by course
having count(student) > 500;

CREATE OR REPLACE VIEW Q5 AS
SELECT a.id AS course_id, STRING_AGG(p.given, '; ' ORDER BY p.given) AS staff_name
FROM a7 a
JOIN course_staff cs ON cs.course = a.id
JOIN people p ON p.id = cs.staff
WHERE p.title LIKE 'Prof'
GROUP BY a.id;

-- Q6:
create or replace view a8(id) as
select id
from courses
where semester in (
select id
from semesters
where year = 2012
);

create or replace view a9(room) as
SELECT c.room
FROM classes c
JOIN a8 a ON a.id = c.course
GROUP BY c.room
HAVING COUNT(a.id) = (
    SELECT MAX(course_count)
    FROM (
        SELECT COUNT(a.id) AS course_count
        FROM classes c
        JOIN a8 a ON a.id = c.course
        GROUP BY c.room
    ) AS max_counts
);

create or replace view a10(max_count, course) as
SELECT COUNT(course) AS max_count, course
FROM classes
WHERE room in (select * from a9)
GROUP BY course
HAVING COUNT(course) = (
    SELECT MAX(course_count)
    FROM (
        SELECT COUNT(course) AS course_count
        FROM classes
        WHERE room in (select * from a9)
        GROUP BY course
    ) AS max_counts
);

create or replace view Q6(room_id, subject_code) as
SELECT cl.room, s.code 
FROM classes cl
JOIN courses co ON cl.course = co.id
JOIN subjects s ON co.subject = s.id
WHERE s.id IN (
    SELECT subject
    FROM courses
    WHERE id IN (
        SELECT course
        FROM a10)
    )
AND cl.room IN (SELECT * FROM a9)
group by cl.room, s.code;

-- Q7:
create or replace view a11(id, semester, program, uoc, org) as
select pe.student, pe.semester, p.id, p.uoc, p.offeredby
from program_enrolments pe
join programs p on pe.program=p.id;

create or replace view a12(id, org) as
select id, org
from a11
group by id, org
having count(distinct program) > 1;

create or replace view a13(id, semester, program, org, uoc) as
select id, semester, program, org, uoc
from a11 where id in (select id from a12);

create or replace view a14(id, program, semester, course, subject) as
select a.id, a.program, a.semester, c.id, s.id
from a13 a
join course_enrolments ce on ce.student=a.id
join courses c on c.id=ce.course and c.semester=a.semester
join subjects s on s.id=c.subject
where ce.mark >= 50;

create or replace view a15(id, program, uoc) as
select a14.id ,a14.program, a13.uoc
from a14
join subjects s on s.id=a14.subject
join a13 on a13.id=a14.id and a13.program=a14.program and a13.semester=a14.semester
group by a14.id, a14.program, a13.uoc
having sum(s.uoc) >= a13.uoc;

create or replace view b6(id) as
select id
from a15
group by id
having count(program) > 1;

create or replace view b7(id, program) as
select b6.id, a.program
from b6
join a15 a on b6.id=a.id;

create or replace view b8(id, program, org) as
select distinct b.id, b.program, a.org
from b7 b
join a13 a on b.id=a.id and a.program=b.program;

create or replace view b9(id) as
select id
from b8
group by id
having count(distinct org)=1;

create or replace view a16(id, program, starting, ending) as
SELECT distinct a.id, a.program, s.starting, s.ending
FROM b7 a 
JOIN program_enrolments pe ON a.id = pe.student
JOIN semesters s ON s.id = pe.semester
where a.id in (select id from b9);

create or replace view a17(id, duration) as
select id, max(ending) - min(starting)
from a16
group by id
having max(ending) - min(starting) < 1000;

create or replace view Q7(student_id, program_id) as
select distinct p.unswid, a.program
from a16 a 
join people p on p.id=a.id
where a.id in (select id from a17);

-- Q8:
create or replace view a18(id, unswid, org) as
select a.staff, p.unswid, a.orgunit
from affiliations a
join orgunits o on o.id=a.orgunit
join people p on p.id=a.staff
group by a.staff, a.orgunit , p.unswid
having count(role) > 2;

create or replace view a19(id, unswid, course) as
select distinct a.id, a.unswid, c.id
from a18 a
join course_staff cs on a.id=cs.staff
join courses c on c.id=cs.course
join semesters s on s.id=c.semester
where s.year=2012
and cs.role=(select id from staff_roles where name = 'Course Convenor');

create or replace view b2(id, unswid) as
select distinct id, unswid from a19;

create or replace view a20(unswid, count_roles) as
select b.unswid, count(af.role)
from b2 b
join affiliations af on b.id=af.staff
group by b.unswid;

create or replace view a21(unswid, hdn_rate) as
SELECT a.unswid,
       CASE 
           WHEN COUNT(ce.mark) >= 0 THEN 
               ROUND(CAST(COUNT(CASE WHEN ce.mark >= 75 THEN 1 END) AS numeric) / COUNT(ce.mark), 2)
           ELSE
               0
       END AS pass_ratio
FROM a19 a
JOIN course_staff cs ON a.id = cs.staff
JOIN course_enrolments ce ON a.course = ce.course
GROUP BY a.unswid;

create or replace view Q8(staff_id, sum_roles, hdn_rate) as
SELECT a20.unswid, a20.count_roles, a21.hdn_rate
FROM a20
JOIN a21 ON a20.unswid = a21.unswid
ORDER BY a21.hdn_rate DESC
LIMIT 21;

-- Q9
create or replace view a22(scode, cid, prereq, sid, mark) as
select s.code, c.id, s._prereq, ce.student, ce.mark
from subjects s
join courses c on c.subject=s.id
join course_enrolments ce on c.id=ce.course
where ce.mark is not null 
AND s._prereq LIKE '%' || LEFT(s.code, 4) || '%';

CREATE OR REPLACE VIEW a23(course, sid, mark, rank) AS
select course, student, mark , RANK() OVER (PARTITION BY course ORDER BY COALESCE(mark, 0) DESC)
from course_enrolments;

CREATE OR REPLACE VIEW a24(sid, scode, rank, prereq) AS
select distinct a22.sid, scode, rank, prereq
from a22
join a23 on a22.sid=a23.sid and a22.cid=a23.course;

CREATE OR REPLACE FUNCTION Q9(unswid integer) RETURNS SETOF text AS $$
BEGIN
    RETURN QUERY
    SELECT 
        scode || ' ' || rank
    FROM a24
    WHERE sid IN (SELECT p.id FROM people p WHERE p.unswid = $1);

    IF NOT FOUND THEN
        RETURN NEXT 'WARNING: Invalid Student Input [' || $1 || ']';
    END IF;
END
$$ LANGUAGE plpgsql;

-- Q10
CREATE OR REPLACE VIEW a25(id, mark, course, grade, subject, uoc) AS
select p.id, ce.mark, ce.course, ce.grade, c.subject, s.uoc
from course_enrolments ce 
join people p on p.id=ce.student
join courses c on c.id=ce.course
join subjects s on s.id=c.subject
where ce.mark is not null;

CREATE OR REPLACE VIEW a26(id, jc, uoc, wam) AS
select a.id, cast(sum(a.mark * a.uoc) as float), sum(a.uoc), ROUND(CAST(SUM(a.mark * a.uoc) AS numeric) / SUM(a.uoc), 2)
from a25 a
group by a.id;

CREATE OR REPLACE VIEW a27(id, program, name, semester) AS
select distinct a.id, pe.program, p.name, pe.semester
from a26 a
join program_enrolments pe on a.id=pe.student
join programs p on pe.program=p.id;

CREATE OR REPLACE VIEW b3(id, name, semester, program, course) AS
select a.id, a.name, a.semester, a.program, c.id
from a27 a
join courses c on c.semester=a.semester;

CREATE OR REPLACE VIEW b4(id, name, program, course, mark, grade, uoc) AS
select b.id, b.name, b.program, a.course, a.mark, a.grade, a.uoc
from b3 b
join a25 a on b.id=a.id and b.course=a.course;

CREATE OR REPLACE VIEW b5(id, name, jc, uoc, wam) AS
select id, name, cast(sum(b.mark * b.uoc) as float), sum(b.uoc), ROUND(CAST(SUM(b.mark * b.uoc) AS numeric) / SUM(b.uoc), 2)
from b4 b
group by id, name, program;

CREATE OR REPLACE FUNCTION Q10(unswid integer) RETURNS SETOF text AS $$
    DECLARE
    program_count INT;
    sy_program INT;
    program_name text;
BEGIN
    SELECT DISTINCT program
    INTO sy_program
    FROM a27 
    WHERE id = (SELECT p.id FROM people p WHERE p.unswid = $1)
    except 
    select distinct program
    from b4
    where id = (SELECT p.id FROM people p WHERE p.unswid = $1);
    select count(distinct program) into program_count from a27 where id = (SELECT p.id FROM people p WHERE p.unswid = $1);
    
    RETURN QUERY
    SELECT 
        $1 || ' ' || b.name || ' ' || b.wam
    FROM b5 b
    WHERE b.id = (SELECT p.id FROM people p WHERE p.unswid = $1);

    IF NOT FOUND THEN
        RETURN NEXT 'WARNING: Invalid Student Input [' || $1 || ']';
    END IF;

    IF program_count <> (SELECT count(*) FROM b5 WHERE id = (SELECT p.id FROM people p WHERE p.unswid = $1)) THEN
        select name into program_name from a27 where program=sy_program; 
        RETURN NEXT $1 || ' ' || program_name || ' No WAM Available';
    END IF;
END
$$ LANGUAGE plpgsql;
