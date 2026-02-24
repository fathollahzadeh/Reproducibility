WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount, 
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM Votes v
    GROUP BY v.PostId
),
ClosedPostHistories AS (
    SELECT 
        ph.PostId,
        STRING_AGG(pt.Name, ', ') AS ClosedReasons
    FROM PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId
),
PostsWithBadges AS (
    SELECT 
        p.Id AS PostId,
        b.Name AS BadgeName,
        b.Class AS BadgeClass,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY b.Date DESC) AS BadgeRank
    FROM Posts p
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(pvc.UpvoteCount, 0) AS Upvotes,
    COALESCE(pvc.DownvoteCount, 0) AS Downvotes,
    COALESCE(cph.ClosedReasons, 'No Close Reasons') AS CloseReasons,
    PWB.BadgeName AS LatestBadge,
    CASE 
        WHEN rp.Score > 100 THEN 'Expert'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Proficient'
        ELSE 'Novice'
    END AS UserLevel
FROM RankedPosts rp
LEFT JOIN PostVoteCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN ClosedPostHistories cph ON rp.PostId = cph.PostId
LEFT JOIN PostsWithBadges PWB ON rp.PostId = PWB.PostId AND PWB.BadgeRank = 1
WHERE rp.rn <= 5 
ORDER BY rp.CreationDate DESC;