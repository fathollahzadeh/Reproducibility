WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 1) THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.UpVotes,
    up.DownVotes,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    cp.CloseCount,
    cp.LastClosedDate,
    CASE 
        WHEN cp.CloseCount IS NULL THEN 'Not Closed'
        ELSE 'Closed'
    END AS ClosureStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    UserActivity up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    LATERAL (SELECT UNNEST(string_to_array(p.Tags, '><')) AS TagName) AS t ON TRUE
WHERE 
    up.Reputation >= 1000
GROUP BY 
    up.UserId, up.DisplayName, up.Reputation, up.UpVotes, up.DownVotes,
    rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, 
    cp.CloseCount, cp.LastClosedDate
ORDER BY 
    up.Reputation DESC, rp.CreationDate DESC
LIMIT 50;