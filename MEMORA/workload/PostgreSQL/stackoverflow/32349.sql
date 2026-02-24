
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyEarned
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        ur.DisplayName AS OwnerDisplayName,
        ur.Reputation AS OwnerReputation,
        ur.TotalBountyEarned
    FROM RankedPosts rp
    JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE rp.rn = 1
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        p.Title AS ClosedTitle,
        ph.Comment AS CloseReason
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId = 10  
),
FinalOutput AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.OwnerDisplayName,
        ps.OwnerReputation,
        ps.TotalBountyEarned,
        cp.CloseDate,
        cp.ClosedTitle,
        cp.CloseReason
    FROM PostStatistics ps
    LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
)

SELECT 
    fo.PostId,
    fo.Title,
    fo.CreationDate,
    fo.Score,
    fo.ViewCount,
    fo.CommentCount,
    fo.OwnerDisplayName,
    fo.OwnerReputation,
    fo.TotalBountyEarned,
    CASE 
        WHEN fo.CloseDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    COALESCE(fo.CloseReason, 'N/A') AS CloseReasonDetails
FROM FinalOutput fo
ORDER BY fo.Score DESC, fo.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
