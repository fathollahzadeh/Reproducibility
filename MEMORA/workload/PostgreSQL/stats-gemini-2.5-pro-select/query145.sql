 
 WITH f_posts AS
  (SELECT Id,
          OwnerUserId
   FROM posts
   WHERE PostTypeId = 1
     AND AnswerCount >= 0
     AND CreationDate BETWEEN '2010-07-21 15:23:53'::timestamp AND '2014-09-11 23:26:14'::timestamp),
     f_users AS
  (SELECT Id
   FROM users
   WHERE UpVotes >= 0
     AND CreationDate <= '2014-09-11 20:31:48' :: timestamp),
     f_plinks AS
  (SELECT PostId
   FROM postLinks
   WHERE CreationDate BETWEEN '2010-11-16 01:27:37'::timestamp AND '2014-08-21 15:25:23'::timestamp),
     f_phist AS
  (SELECT PostId
   FROM postHistory
   WHERE PostHistoryTypeId = 5),
     f_votes AS
  (SELECT PostId
   FROM votes
   WHERE CreationDate >= '2010-07-21 00:00:00' :: timestamp)
SELECT COUNT(*)
FROM f_posts p
JOIN f_users u ON u.Id = p.OwnerUserId
JOIN f_votes v ON p.Id = v.PostId
JOIN comments c ON p.Id = c.PostId
JOIN f_plinks pl ON p.Id = pl.PostId
JOIN f_phist ph ON p.Id = ph.PostId;