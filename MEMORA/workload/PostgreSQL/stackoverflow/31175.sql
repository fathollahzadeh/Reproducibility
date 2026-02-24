
WITH RECURSIVE UserBadgeCount AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        MIN(Date) AS FirstBadgeDate
    FROM Badges
    GROUP BY UserId
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.CreationDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
TopPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.Score,
        ub.BadgeCount,
        pa.CommentCount,
        pa.VoteCount
    FROM PostAnalytics pa
    JOIN UserBadgeCount ub ON pa.OwnerUserId = ub.UserId
    WHERE ub.BadgeCount > 0
    ORDER BY pa.Score DESC
    LIMIT 10
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.Title,
        p.OwnerUserId,
        p.Score,
        PHT.Name AS HistoryType
    FROM PostHistory ph
    JOIN PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    tp.Title AS TopPostTitle,
    tp.CreationDate AS TopPostDate,
    tp.Score AS TopPostScore,
    tp.CommentCount AS TopPostCommentCount,
    tp.VoteCount AS TopPostVoteCount,
    rph.Title AS RecentPostTitle,
    rph.CreationDate AS RecentEditDate,
    rph.HistoryType AS RecentEditType
FROM TopPosts tp
LEFT JOIN RecentPostHistory rph ON tp.PostId = rph.PostId
ORDER BY tp.Score DESC, rph.CreationDate DESC NULLS LAST;
