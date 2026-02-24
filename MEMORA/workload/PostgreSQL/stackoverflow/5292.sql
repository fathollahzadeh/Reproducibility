
WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           COUNT(c.Id) AS CommentCount, 
           AVG(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount, 
           AVG(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes vt ON p.Id = vt.PostId
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.CreationDate
), UserStats AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           SUM(CASE WHEN rp.CommentCount > 0 THEN 1 ELSE 0 END) AS PostsWithComments,
           SUM(rp.UpvoteCount) AS TotalUpvotes,
           SUM(rp.DownvoteCount) AS TotalDownvotes
    FROM Users u
    LEFT JOIN RankedPosts rp ON u.Id = rp.Id
    GROUP BY u.Id, u.DisplayName
)
SELECT us.DisplayName, 
       us.PostsWithComments,
       us.TotalUpvotes, 
       us.TotalDownvotes,
       COALESCE(ROUND((us.TotalUpvotes::decimal / NULLIF((us.TotalUpvotes + us.TotalDownvotes), 0)) * 100, 2), 0) AS UpvotePercentage
FROM UserStats us
WHERE us.PostsWithComments > 0
ORDER BY us.TotalUpvotes DESC, us.DisplayName
LIMIT 10;
