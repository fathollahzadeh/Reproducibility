WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.Score > 0
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
), 
TopUsers AS (
    SELECT 
        ur.UserId, 
        ur.Reputation,
        ur.BadgeCount
    FROM 
        UserReputation ur
    WHERE 
        ur.Reputation > 1000
), 
PostDetails AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.Id = u.Id 
    WHERE 
        rp.rn = 1
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = pd.PostId) AS CommentCount,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     WHERE t.WikiPostId = pd.PostId) AS Tags
FROM 
    PostDetails pd
JOIN 
    TopUsers tu ON pd.OwnerReputation = tu.Reputation
WHERE 
    pd.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
ORDER BY 
    pd.ViewCount DESC
LIMIT 10
OFFSET 5;
