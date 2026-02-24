WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(ph.Id) AS TotalPostHistoryEntries,
        COUNT(DISTINCT ph.PostId) AS UniquePostsEdited
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.Questions,
    u.Answers,
    u.TotalScore,
    u.TotalViews,
    COALESCE(ph.TotalPostHistoryEntries, 0) AS TotalPostHistoryEntries,
    COALESCE(ph.UniquePostsEdited, 0) AS UniquePostsEdited
FROM 
    UserPostStats u
LEFT JOIN 
    PostHistoryStats ph ON u.UserId = ph.OwnerUserId
ORDER BY 
    u.TotalScore DESC;