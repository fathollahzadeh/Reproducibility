
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.Id, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.Reputation
), 
TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.Id, t.TagName
)

SELECT 
    us.UserId,
    us.Reputation,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.TotalViews AS UserTotalViews,
    us.TotalScore,
    us.TotalComments,
    ts.TagId,
    ts.TagName,
    ts.PostCount AS TagPostCount,
    ts.TotalViews AS TagTotalViews
FROM 
    UserStats us
JOIN 
    TagStats ts ON us.TotalPosts > 50  
ORDER BY 
    us.Reputation DESC, ts.PostCount DESC
LIMIT 100;
