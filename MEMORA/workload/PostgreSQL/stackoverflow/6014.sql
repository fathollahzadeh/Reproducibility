WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           COUNT(c.Id) AS CommentCount, 
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes, 
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.PostTypeId IN (1, 2) 
    GROUP BY p.Id
), UserPostStats AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           u.Reputation, 
           COUNT(DISTINCT rp.Id) AS PostCount, 
           SUM(rp.Upvotes) AS TotalUpvotes, 
           SUM(rp.Downvotes) AS TotalDownvotes
    FROM Users u
    JOIN RankedPosts rp ON rp.Id = u.Id
    WHERE rp.rn = 1 
    GROUP BY u.Id
), UserBadges AS (
    SELECT UserId, 
           COUNT(*) FILTER (WHERE Class = 1) AS GoldBadges, 
           COUNT(*) FILTER (WHERE Class = 2) AS SilverBadges, 
           COUNT(*) FILTER (WHERE Class = 3) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)
SELECT u.DisplayName, 
       u.Reputation, 
       u.PostCount, 
       u.TotalUpvotes, 
       u.TotalDownvotes, 
       ub.GoldBadges, 
       ub.SilverBadges, 
       ub.BronzeBadges
FROM UserPostStats u
LEFT JOIN UserBadges ub ON u.UserId = ub.UserId
ORDER BY u.Reputation DESC, u.TotalUpvotes DESC
LIMIT 10;