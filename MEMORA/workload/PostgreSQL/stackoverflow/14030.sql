WITH PostsAggregated AS (
    SELECT 
        pst.OwnerUserId,
        COUNT(pst.Id) AS PostCount,
        SUM(pst.ViewCount) AS TotalViews,
        SUM(pst.Score) AS TotalScore,
        AVG(pst.Score) AS AvgScore
    FROM 
        Posts pst
    WHERE 
        pst.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        pst.OwnerUserId
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(pa.PostCount, 0) AS PostCount,
        COALESCE(pa.TotalViews, 0) AS TotalViews,
        COALESCE(pa.TotalScore, 0) AS TotalScore,
        COALESCE(pa.AvgScore, 0) AS AvgScore,
        u.Reputation,
        u.CreationDate
    FROM 
        Users u
    LEFT JOIN 
        PostsAggregated pa ON u.Id = pa.OwnerUserId
)
SELECT 
    um.UserId,
    um.DisplayName,
    um.PostCount,
    um.TotalViews,
    um.TotalScore,
    um.AvgScore,
    um.Reputation,
    um.CreationDate
FROM 
    UserMetrics um
ORDER BY 
    um.TotalViews DESC, 
    um.TotalScore DESC;