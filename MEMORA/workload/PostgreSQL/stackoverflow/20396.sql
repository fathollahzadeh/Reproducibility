
WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount, 
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
PostDetails AS (
    SELECT rp.Id, rp.Title, rp.CreationDate, rp.Score, rp.CommentCount, rp.UpvoteCount, rp.DownvoteCount,
           CASE 
               WHEN rp.Score > 0 THEN 'Positive'
               WHEN rp.Score < 0 THEN 'Negative'
               ELSE 'Neutral'
           END AS ScoreType
    FROM RankedPosts rp
    WHERE rp.UserPostRank <= 5
),
RecentBadges AS (
    SELECT b.UserId, STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    WHERE b.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY b.UserId
),
FilteredPosts AS (
    SELECT pd.*, rb.BadgeNames
    FROM PostDetails pd
    LEFT JOIN RecentBadges rb ON pd.Id = rb.UserId
)
SELECT fp.Id, fp.Title, fp.CreationDate, fp.Score,
       fp.CommentCount, fp.UpvoteCount, fp.DownvoteCount,
       fp.ScoreType, 
       COALESCE(fp.BadgeNames, 'No Badges') AS BadgeInfo
FROM FilteredPosts fp
WHERE fp.ScoreType = 'Positive' AND fp.CommentCount > 0
ORDER BY fp.Score DESC, fp.CreationDate ASC
LIMIT 10;
