 
 WITH u AS
  (SELECT id
   FROM users
   WHERE UpVotes = 0),
     c AS
  (SELECT UserId
   FROM comments
   WHERE CreationDate >= '2010-07-20 21:37:31' :: timestamp),
     ph AS
  (SELECT UserId
   FROM postHistory
   WHERE PostHistoryTypeId = 12)
SELECT COUNT(*)
FROM u
JOIN c ON u.id = c.UserId
JOIN ph ON u.id = ph.UserId
JOIN badges b ON u.id = b.UserId
JOIN votes v ON u.id = v.UserId;