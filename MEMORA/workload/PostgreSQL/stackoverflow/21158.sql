
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        AVG(v.BountyAmount) OVER (PARTITION BY p.Id) AS AvgBounty
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        COUNT(*) AS CloseCount,
        STRING_AGG(CASE WHEN ph.Comment IS NOT NULL THEN ph.Comment ELSE 'No comment' END, '; ') AS CloseReason
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId
),
ActiveUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id
    HAVING SUM(u.UpVotes) > SUM(u.DownVotes)
),
FinalStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(cp.CloseCount, 0) AS TotalCloseCount,
        cp.FirstClosedDate,
        au.DisplayName AS ActiveUserName,
        au.CommentCount AS ActiveUserCommentCount,
        au.TotalUpVotes,
        au.TotalDownVotes,
        CASE 
            WHEN rp.ViewCount > 1000 THEN 'Highly Viewed'
            WHEN rp.ViewCount BETWEEN 500 AND 1000 THEN 'Moderately Viewed'
            ELSE 'Low Viewed'
        END AS ViewCategory
    FROM RankedPosts rp
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN ActiveUsers au ON au.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId LIMIT 1)
    WHERE rp.PostRank <= 10
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.CreationDate,
    fs.ViewCount,
    fs.Score,
    fs.TotalCloseCount,
    fs.FirstClosedDate,
    fs.ActiveUserName,
    fs.ActiveUserCommentCount,
    fs.TotalUpVotes,
    fs.TotalDownVotes,
    fs.ViewCategory,
    CASE 
        WHEN fs.TotalCloseCount > 0 THEN 'This post has been closed.'
        ELSE 'This post is open for discussion.'
    END AS PostStatus
FROM FinalStats fs
ORDER BY fs.Score DESC, fs.ViewCount DESC
LIMIT 50;
