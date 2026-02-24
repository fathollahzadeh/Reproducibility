
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 50
),
PostDetails AS (
    SELECT 
        rp.Title,
        rp.ViewCount,
        rp.CommentCount,
        tu.DisplayName AS TopUserDisplayName,
        tu.TotalScore,
        tu.TotalViews,
        rp.Rank,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopUsers tu ON rp.OwnerUserId = tu.UserId
)
SELECT 
    pd.*,
    COALESCE(pd.TotalScore, 0) AS TotalScore,
    CASE 
        WHEN pd.CommentCount > 10 THEN 'High Engagement'
        WHEN pd.CommentCount BETWEEN 5 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostDetails pd
WHERE 
    pd.Rank = 1
ORDER BY 
    pd.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
