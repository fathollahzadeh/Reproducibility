WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           u.DisplayName AS OwnerDisplayName,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS RN
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
),
TopRankedPosts AS (
    SELECT PostId,
           Title,
           CreationDate,
           Score,
           ViewCount,
           OwnerDisplayName
    FROM RankedPosts 
    WHERE RN <= 5
),
PostComments AS (
    SELECT pc.PostId,
           COUNT(pc.Id) AS CommentCount
    FROM Comments pc
    GROUP BY pc.PostId
),
PostBadges AS (
    SELECT b.UserId,
           COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
FinalResults AS (
    SELECT trp.PostId,
           trp.Title,
           trp.CreationDate,
           trp.Score,
           trp.ViewCount,
           pc.CommentCount,
           ub.BadgeCount
    FROM TopRankedPosts trp
    LEFT JOIN PostComments pc ON trp.PostId = pc.PostId
    LEFT JOIN PostBadges ub ON ub.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = trp.PostId)
)
SELECT *,
       CASE 
           WHEN Score >= 100 THEN 'High Score'
           WHEN Score BETWEEN 50 AND 99 THEN 'Medium Score'
           ELSE 'Low Score'
       END AS ScoreCategory
FROM FinalResults
ORDER BY Score DESC, ViewCount DESC;