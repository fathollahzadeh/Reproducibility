
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC NULLS LAST) AS Rank
    FROM 
        Posts p
    WHERE 
        (p.PostTypeId = 1 OR p.PostTypeId = 2) 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
RankedUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.TotalBadges,
        ur.PostCount,
        NTILE(10) OVER (ORDER BY ur.Reputation DESC) AS ReputationTier
    FROM 
        UserReputation ur
    WHERE 
        ur.Reputation IS NOT NULL
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId, 
    rp.Title,
    rp.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    pv.UpVotes,
    pv.DownVotes,
    pv.TotalVotes,
    rp.Rank,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top Tier'
        WHEN rp.Rank <= 50 THEN 'Mid Tier'
        ELSE 'Low Tier'
    END AS PostRankCategory,
    COALESCE(ru.ReputationTier, 10) AS UserReputationTier
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    RankedUsers ru ON u.Id = ru.UserId
LEFT JOIN 
    PostVoteCounts pv ON rp.PostId = pv.PostId
WHERE 
    (rp.Rank <= 100 OR pv.TotalVotes > 5) 
    AND (rp.ViewCount > 0 OR pv.UpVotes IS NOT NULL) 
ORDER BY 
    rp.ViewCount DESC, 
    pv.UpVotes DESC, 
    rp.Rank
OFFSET 0 ROWS 
FETCH NEXT 50 ROWS ONLY;
