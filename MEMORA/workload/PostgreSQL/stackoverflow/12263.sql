WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostStatistics AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(rp.Id) AS PostCount,
        AVG(rp.Score) AS AvgScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM RecentPosts rp
    GROUP BY rp.OwnerDisplayName
),
TopUsers AS (
    SELECT 
        ps.OwnerDisplayName,
        ps.PostCount,
        ps.AvgScore,
        ps.TotalViews,
        ROW_NUMBER() OVER (ORDER BY ps.TotalViews DESC) AS Rank
    FROM PostStatistics ps
)
SELECT 
    Rank,
    OwnerDisplayName,
    PostCount,
    AvgScore,
    TotalViews
FROM TopUsers
WHERE Rank <= 10
ORDER BY Rank;