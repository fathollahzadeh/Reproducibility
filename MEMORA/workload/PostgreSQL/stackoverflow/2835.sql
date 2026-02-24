WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(NULLIF(u.DisplayName, ''), 'Anonymous') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score > 0
),
PostStats AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(rp.Id) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AverageViews,
        MAX(rp.CreationDate) AS MostRecentPostDate
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.OwnerDisplayName
),
CommentCount AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentTotal
    FROM 
        Comments
    GROUP BY 
        PostId
),
FinalResults AS (
    SELECT
        ps.OwnerDisplayName,
        ps.TotalPosts,
        ps.TotalScore,
        ps.AverageViews,
        ps.MostRecentPostDate,
        COALESCE(cc.CommentTotal, 0) AS TotalComments
    FROM 
        PostStats ps
    LEFT JOIN 
        CommentCount cc ON cc.PostId = (
            SELECT Id FROM Posts WHERE OwnerDisplayName = ps.OwnerDisplayName ORDER BY CreationDate DESC LIMIT 1
        )
)
SELECT 
    OwnerDisplayName,
    TotalPosts,
    TotalScore,
    AverageViews,
    MostRecentPostDate,
    TotalComments
FROM 
    FinalResults
WHERE 
    TotalPosts > 5 AND TotalScore > 50
ORDER BY 
    TotalScore DESC, TotalPosts ASC;