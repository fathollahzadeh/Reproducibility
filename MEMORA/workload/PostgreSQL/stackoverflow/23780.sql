
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum,
        AVG(v.VoteTypeId) OVER (PARTITION BY p.Id) AS AvgVoteType
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
ClosedPostStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastCloseDate,
        STRING_AGG(ct.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes ct ON CAST(ph.Comment AS INT) = ct.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COALESCE(SUM(b.Class), 0) AS BadgeCount,
        MAX(u.LastAccessDate) AS LastActiveDate
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(cps.CloseCount, 0) AS CloseCount,
    cps.LastCloseDate,
    COALESCE(cps.CloseReasons, 'No Reasons') AS CloseReasons,
    au.UserId,
    au.DisplayName AS AuthorName,
    au.PostsCount,
    au.BadgeCount,
    au.LastActiveDate,
    (CASE 
        WHEN rp.AvgVoteType IS NULL THEN 'No Votes'
        WHEN rp.AvgVoteType > 3 THEN 'Highly Voted'
        ELSE 'Low Voted'
    END) AS VoteCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPostStats cps ON rp.PostId = cps.PostId
JOIN 
    ActiveUsers au ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = au.UserId)
WHERE 
    rp.RowNum <= 5 
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC
LIMIT 100;
