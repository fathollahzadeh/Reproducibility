
WITH RecursiveTopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    u.DisplayName,
    u.Reputation,
    t.Title,
    t.ViewCount,
    ph.LastEditDate,
    RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    CASE 
        WHEN ph.LastEditDate IS NOT NULL THEN 'Has Recent Edits'
        ELSE 'No Recent Edits'
    END AS EditStatus
FROM 
    UserReputation u
JOIN 
    RecursiveTopPosts t ON u.UserId = t.OwnerUserId
LEFT JOIN 
    Badges b ON u.UserId = b.UserId
LEFT JOIN 
    RecentActivity ph ON t.Id = ph.PostId
WHERE 
    t.RowNum <= 3  
GROUP BY 
    u.DisplayName, u.Reputation, t.Title, t.ViewCount, ph.LastEditDate
ORDER BY 
    UserRank, u.DisplayName;
