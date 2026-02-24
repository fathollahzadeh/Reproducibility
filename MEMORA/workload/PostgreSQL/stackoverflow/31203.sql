
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Location,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.Location
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, ', ') AS Comments,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.CommentCount,
    COALESCE(h.Comments, 'No edits') AS HistoryComments,
    h.FirstEditDate,
    h.LastEditDate,
    h.EditCount,
    'Rank: ' || CAST(r.Rank AS VARCHAR) AS UserPostRank,
    CASE 
        WHEN u.Location IS NULL THEN 'Location Unknown' 
        ELSE u.Location 
    END AS UserLocation
FROM 
    RankedPosts r
JOIN 
    UserReputation u ON r.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistoryDetails h ON r.PostId = h.PostId
WHERE 
    r.Rank <= 3 
ORDER BY 
    u.Reputation DESC,
    r.Score DESC;
