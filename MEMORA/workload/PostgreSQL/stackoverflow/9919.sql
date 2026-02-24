WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
), TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostCount,
        us.Questions,
        us.Answers,
        us.TotalViews,
        us.TotalScore,
        bc.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY us.TotalScore DESC, us.PostCount DESC, us.TotalViews DESC) AS Ranking
    FROM 
        UserStats us
    LEFT JOIN 
        BadgeCounts bc ON us.UserId = bc.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    Questions,
    Answers,
    TotalViews,
    TotalScore,
    BadgeCount,
    Ranking
FROM 
    TopUsers
WHERE 
    Ranking <= 10
ORDER BY 
    TotalScore DESC, PostCount DESC;
