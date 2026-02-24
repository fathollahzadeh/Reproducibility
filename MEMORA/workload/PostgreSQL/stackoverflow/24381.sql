
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.ViewCount > 100
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentCloseReasons AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastClosed,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        p.Id
),
AggregatePostStats AS (
    SELECT 
        p.Id AS PostId,
        AVG(COALESCE(c.Score, 0)) AS AverageCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    u.DisplayName,
    us.UpVotes,
    us.DownVotes,
    us.BadgeCount,
    rcr.CloseReasons,
    aps.AverageCommentScore
FROM 
    RankedPosts rp
INNER JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    RecentCloseReasons rcr ON rp.Id = rcr.PostId
LEFT JOIN 
    AggregatePostStats aps ON rp.Id = aps.PostId
WHERE 
    (rp.PostTypeId = 1 AND rp.rn <= 5)
    OR (rp.PostTypeId = 2 AND u.Reputation >= 100)
ORDER BY 
    COALESCE(rcr.LastClosed, '1900-01-01') DESC,
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
