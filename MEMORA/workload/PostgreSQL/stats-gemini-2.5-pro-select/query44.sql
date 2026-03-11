 
 WITH f_users AS
  (SELECT u.Id
   FROM users AS u
   WHERE u.Views >= 0
     AND u.DownVotes BETWEEN 0 AND 0
     AND u.UpVotes BETWEEN 0 AND 37),
     agg_posts AS
  (SELECT p.OwnerUserId,
          COUNT(*) AS post_count
   FROM posts AS p
   WHERE p.Score >= -1
     AND p.ViewCount BETWEEN 0 AND 39097
     AND p.AnswerCount >= 0
     AND p.CommentCount BETWEEN 0 AND 11
     AND p.FavoriteCount <= 10
     AND p.CreationDate BETWEEN '2010-08-13 02:18:09'::timestamp AND '2014-09-09 10:20:27'::timestamp
   GROUP BY p.OwnerUserId),
     agg_ph AS
  (SELECT ph.UserId,
          COUNT(*) AS ph_count
   FROM postHistory AS ph
   WHERE ph.CreationDate BETWEEN '2010-09-06 11:41:43'::timestamp AND '2014-09-03 16:41:18'::timestamp
   GROUP BY ph.UserId),
     agg_badges AS
  (SELECT b.UserId,
          COUNT(*) AS badge_count
   FROM badges AS b
   GROUP BY b.UserId)
SELECT SUM(ap.post_count * aph.ph_count * ab.badge_count)
FROM f_users
JOIN agg_posts AS ap ON f_users.Id = ap.OwnerUserId
JOIN agg_ph AS aph ON f_users.Id = aph.UserId
JOIN agg_badges AS ab ON f_users.Id = ab.UserId;