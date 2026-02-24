
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
MostActiveUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.UpVotes,
        us.DownVotes,
        us.PostCount,
        RANK() OVER (ORDER BY us.PostCount DESC) AS UserRank
    FROM 
        UserStats us
    WHERE 
        us.PostCount > 10
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(c.CloseReason, 'Not Closed') AS CloseReason,
    mu.DisplayName AS TopUser,
    mu.UpVotes,
    mu.DownVotes,
    mu.PostCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts c ON rp.PostId = c.PostId
JOIN 
    MostActiveUsers mu ON mu.UserId = rp.PostId % (SELECT COUNT(*) FROM Users)
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
