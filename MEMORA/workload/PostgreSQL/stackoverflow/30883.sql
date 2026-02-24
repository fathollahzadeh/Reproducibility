WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pr.CreationDate AS PostDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts pr ON p.AcceptedAnswerId = pr.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        v.PostId
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastEditDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    r.PostId,
    r.Title,
    r.PostDate,
    r.ViewCount,
    r.Score,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    hp.LastEditDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    COALESCE(b.BadgeCount, 0) AS TotalBadges
FROM 
    RecursiveCTE r
LEFT JOIN 
    PostVotes v ON r.PostId = v.PostId
LEFT JOIN 
    PostHistoryCTE hp ON r.PostId = hp.PostId
JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
WHERE 
    r.rn <= 5 
ORDER BY 
    r.ViewCount DESC, r.Score DESC;