 
 
SELECT SUM(
             (SELECT COUNT(*)
              FROM badges b
              WHERE b.UserId = u.Id) *
             (SELECT COUNT(*)
              FROM postHistory ph
              WHERE ph.UserId = u.Id) *
             (SELECT COUNT(*)
              FROM votes v
              WHERE v.UserId = u.Id))
FROM users u
WHERE u.Views >= 0
  AND EXISTS
    (SELECT 1
     FROM badges b
     WHERE b.UserId = u.Id)
  AND EXISTS
    (SELECT 1
     FROM postHistory ph
     WHERE ph.UserId = u.Id)
  AND EXISTS
    (SELECT 1
     FROM votes v
     WHERE v.UserId = u.Id);