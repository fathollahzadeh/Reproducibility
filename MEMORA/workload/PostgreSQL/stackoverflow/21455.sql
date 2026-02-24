
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotesCount,
        p.CreationDate,
        p.LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '1 year') 
        AND (p.Score > 0 OR p.ViewCount > 100)
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 
        AND u.LastAccessDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months')
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.LastAccessDate
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges,
        MAX(CASE WHEN b.Class = 1 THEN 'Gold' END) AS GoldCount,
        MAX(CASE WHEN b.Class = 2 THEN 'Silver' END) AS SilverCount,
        MAX(CASE WHEN b.Class = 3 THEN 'Bronze' END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    r.Title,
    r.ViewCount,
    r.UpVotesCount,
    r.DownVotesCount,
    b.Badges,
    cp.LastClosedDate
FROM 
    ActiveUsers u
JOIN 
    RankedPosts r ON u.UserId = r.OwnerUserId
LEFT JOIN 
    UserBadges b ON u.UserId = b.UserId
LEFT JOIN 
    ClosedPosts cp ON r.PostId = cp.PostId
WHERE 
    r.Rank = 1
    AND (b.Badges IS NOT NULL OR cp.LastClosedDate IS NOT NULL)
ORDER BY 
    u.Reputation DESC,
    r.ViewCount DESC
LIMIT 50;
