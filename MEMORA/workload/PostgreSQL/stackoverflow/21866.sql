
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
    GROUP BY p.Id, p.Title, p.CreationDate, p.PostTypeId, p.Score
),

TopPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CommentCount,
        (rp.UpVotes - rp.DownVotes) AS NetVotes,
        rp.PostTypeId,
        CASE 
            WHEN rp.PostRank <= 10 THEN 'Top 10'
            WHEN rp.PostRank <= 50 THEN 'Top 50'
            ELSE 'Other'
        END AS RankGroup
    FROM RankedPosts rp
    WHERE rp.CommentCount > 0
),

AggBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeList
    FROM Badges b
    WHERE b.Date >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
    GROUP BY b.UserId
),

PostDetails AS (
    SELECT 
        p.Title,
        t.TagName,
        COALESCE(ab.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(ab.BadgeList, 'No Badges') AS UserBadges
    FROM TopPosts p
    JOIN Tags t ON t.WikiPostId = p.PostID
    LEFT JOIN AggBadges ab ON p.PostID = ab.UserId
)

SELECT 
    pd.Title,
    pd.TagName,
    pd.UserBadgeCount,
    pd.UserBadges,
    CASE 
        WHEN pd.UserBadgeCount > 5 THEN 'Veteran User'
        WHEN pd.UserBadgeCount > 0 THEN 'Active Contributor'
        ELSE 'New User'
    END AS UserStatus
FROM PostDetails pd
WHERE pd.UserBadgeCount IS NOT NULL
AND pd.UserBadgeCount < 10
ORDER BY pd.UserBadgeCount DESC, pd.Title
LIMIT 100;
