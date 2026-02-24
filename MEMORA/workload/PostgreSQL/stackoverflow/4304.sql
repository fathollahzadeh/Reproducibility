
WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.ViewCount, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
FilteredComments AS (
    SELECT c.PostId, 
           COUNT(*) AS CommentCount,
           SUM(CASE WHEN c.Score >= 0 THEN 1 ELSE 0 END) AS PositiveComments,
           SUM(CASE WHEN c.Score < 0 THEN 1 ELSE 0 END) AS NegativeComments
    FROM Comments c
    GROUP BY c.PostId
),
PostsWithBadges AS (
    SELECT p.Id AS PostId,
           p.Title,
           b.Class AS BadgeClass,
           b.Name AS BadgeName
    FROM Posts p
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE b.Class IN (1, 2) 
)
SELECT rp.Title, 
       rp.CreationDate, 
       rp.Score, 
       COALESCE(fc.CommentCount, 0) AS CommentCount,
       COALESCE(fc.PositiveComments, 0) AS PositiveComments,
       COALESCE(fc.NegativeComments, 0) AS NegativeComments,
       CASE WHEN pwb.BadgeClass IS NOT NULL THEN 'Yes' ELSE 'No' END AS HasBadge,
       CASE WHEN rp.UserPostRank = 1 THEN 'Most Recent' ELSE 'Older Post' END AS PostRecency
FROM RankedPosts rp
LEFT JOIN FilteredComments fc ON rp.Id = fc.PostId
LEFT JOIN PostsWithBadges pwb ON rp.Id = pwb.PostId
WHERE rp.UserPostRank <= 5
ORDER BY rp.CreationDate DESC;
