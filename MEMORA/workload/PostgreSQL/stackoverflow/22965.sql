WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),

ClosedPostStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS varchar)
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),

UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    r.PostId,
    r.Title AS PostTitle,
    r.Score,
    r.ViewCount,
    r.UpVotes,
    r.DownVotes,
    cb.CloseCount,
    cb.CloseReasons,
    cb.LastCloseDate,
    ub.BadgeNames,
    ub.BadgeCount,
    ub.LastBadgeDate
FROM 
    Users u
LEFT JOIN 
    RankedPosts r ON u.Id = r.PostId
LEFT JOIN 
    ClosedPostStats cb ON r.PostId = cb.PostId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    (cb.LastCloseDate IS NULL OR cb.LastCloseDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days') 
    AND u.Reputation > (SELECT AVG(Reputation) FROM Users) 
ORDER BY 
    r.Score DESC NULLS LAST,
    u.Reputation DESC;