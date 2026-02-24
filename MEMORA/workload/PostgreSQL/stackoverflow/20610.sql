
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId, p.LastActivityDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(b.Name, 'No Badges') AS BadgeName,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, b.Name
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserId
    HAVING 
        COUNT(*) > 2  
)
SELECT 
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    u.UserRank,
    u.Reputation,
    COALESCE(phd.ChangeCount, 0) AS HistoricChanges,
    COALESCE(up.UpVotes, 0) AS UpVotes,
    u.BadgeName
FROM 
    RankedPosts p
JOIN 
    UserReputation u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId = p.PostId
LEFT JOIN 
    (SELECT 
        PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
     FROM 
         Votes 
     GROUP BY 
         PostId) AS up ON up.PostId = p.PostId
WHERE 
    p.Rank = 1  
ORDER BY 
    p.Score DESC,  
    p.ViewCount DESC NULLS LAST,
    u.Reputation DESC;
