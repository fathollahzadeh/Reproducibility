WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL AND p.OwnerUserId IS NOT NULL
), UserReputation AS (
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
), TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        ur.Reputation AS OwnerReputation,
        ur.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserReputation ur ON u.Id = ur.UserId
    WHERE 
        rp.RankScore <= 10
)
SELECT 
    trp.Title,
    trp.Score,
    trp.ViewCount,
    trp.CreationDate,
    trp.LastActivityDate,
    trp.OwnerDisplayName,
    trp.OwnerReputation,
    trp.BadgeCount,
    COUNT(CASE WHEN c.PostId IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount
FROM 
    TopRankedPosts trp
LEFT JOIN 
    Comments c ON trp.PostId = c.PostId
LEFT JOIN 
    Votes v ON trp.PostId = v.PostId
GROUP BY 
    trp.PostId, trp.Title, trp.Score, trp.ViewCount, trp.CreationDate, trp.LastActivityDate, trp.OwnerDisplayName, trp.OwnerReputation, trp.BadgeCount
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
