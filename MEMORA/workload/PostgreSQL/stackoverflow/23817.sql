
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.Score IS NOT NULL AND p.Score >= 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        FIRST_VALUE(u.DisplayName) OVER (PARTITION BY u.Id ORDER BY u.CreationDate ASC) AS FirstDisplayName
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostHistoryAggregates AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.PostType,
    rp.Rank,
    ur.Reputation,
    ur.FirstDisplayName,
    pha.HistoryCount,
    pha.HistoryTypes,
    CASE 
        WHEN rp.Score IS NULL THEN 'No score'
        WHEN rp.Score < 5 THEN 'Low score'
        WHEN rp.Score BETWEEN 5 AND 20 THEN 'Moderate score'
        ELSE 'High score'
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ur ON ur.UserId = (SELECT ParentId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    PostHistoryAggregates pha ON rp.PostId = pha.PostId
WHERE 
    rp.Rank <= 5
    AND (ur.Reputation IS NULL OR ur.Reputation > 5000)
ORDER BY 
    rp.Score DESC NULLS LAST;
