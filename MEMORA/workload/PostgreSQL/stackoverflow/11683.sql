WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AvgPostScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        HOT.Name AS HistoryTypeName,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes HOT ON ph.PostHistoryTypeId = HOT.Id
    GROUP BY 
        ph.UserId, HOT.Name
),
FinalStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.Questions,
        ups.Answers,
        ups.AvgPostScore,
        ups.AvgViewCount,
        COALESCE(phs.HistoryCount, 0) AS HistoryCount
    FROM 
        UserPostStats ups
    LEFT JOIN 
        PostHistoryStats phs ON ups.UserId = phs.UserId
)

SELECT 
    *,
    RANK() OVER (ORDER BY TotalPosts DESC) AS RankByPosts,
    RANK() OVER (ORDER BY HistoryCount DESC) AS RankByHistory
FROM 
    FinalStats
ORDER BY 
    RankByPosts;