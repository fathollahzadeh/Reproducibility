
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)
), PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.ViewCount) > 1000
), RecentActions AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEdit
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
        AND ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    pu.DisplayName AS TopUser,
    pu.TotalViews,
    pu.TotalScore,
    ra.EditCount,
    ra.LastEdit
FROM 
    RankedPosts rp
JOIN 
    PopularUsers pu ON pu.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = rp.PostId)
LEFT JOIN 
    RecentActions ra ON ra.PostId = rp.PostId
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 10;
