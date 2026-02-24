WITH RECURSIVE UserBadgeCounts AS (
    SELECT UserId, 
           COUNT(*) AS BadgeCount,
           SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
RecentPosts AS (
    SELECT p.Id AS PostId,
           p.OwnerUserId,
           p.CreationDate,
           p.Title,
           p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
),
CommentsWithDetails AS (
    SELECT c.Id AS CommentId,
           c.UserId,
           c.PostId,
           c.CreationDate,
           u.DisplayName AS CommenterName,
           c.Text AS CommentText,
           DENSE_RANK() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank,
           COALESCE(c.UserId, -1) AS UserRoleId
    FROM Comments c
    LEFT JOIN Users u ON c.UserId = u.Id
),
VoteSummary AS (
    SELECT PostId,
           SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes
    GROUP BY PostId
)

SELECT u.DisplayName,
       u.Reputation,
       ubc.BadgeCount,
       ubc.GoldBadges,
       ubc.SilverBadges,
       ubc.BronzeBadges,
       rp.Title,
       rp.CreationDate,
       rp.Score,
       COALESCE(vs.Upvotes, 0) AS Upvotes,
       COALESCE(vs.Downvotes, 0) AS Downvotes,
       cd.CommenterName,
       cd.CommentText
FROM Users u
LEFT JOIN UserBadgeCounts ubc ON u.Id = ubc.UserId
INNER JOIN RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.RecentPostRank = 1
LEFT JOIN VoteSummary vs ON rp.PostId = vs.PostId
LEFT JOIN CommentsWithDetails cd ON rp.PostId = cd.PostId AND cd.CommentRank = 1
WHERE u.Reputation > 1000
ORDER BY ubc.BadgeCount DESC, rp.Score DESC;
