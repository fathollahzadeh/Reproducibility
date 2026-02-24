WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS Comments,
        SUM(v.BountyAmount) AS TotalBounties,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        Questions, 
        Answers, 
        Comments, 
        TotalBounties
    FROM 
        UserActivity
    WHERE 
        ActivityRank <= 10
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.Questions,
    u.Answers,
    u.Comments,
    CASE 
        WHEN u.TotalBounties IS NULL THEN 0
        ELSE u.TotalBounties 
    END AS BountySum,
    (SELECT AVG(PostCount) FROM UserActivity) AS AvgPosts
FROM 
    TopUsers u
JOIN 
    Badges b ON u.UserId = b.UserId
WHERE 
    b.Class = 1
ORDER BY 
    u.PostCount DESC, 
    u.UserId;
