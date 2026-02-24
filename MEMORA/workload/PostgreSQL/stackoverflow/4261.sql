
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(AVG(v.BountyAmount), 0) AS AvgBountyAmount,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, TotalPosts, Questions, Answers, AvgBountyAmount
    FROM 
        UserActivity
    WHERE 
        ActivityRank <= 10
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.AvgBountyAmount,
    COALESCE((
        SELECT 
            STRING_AGG(p.Title, ', ')
        FROM 
            Posts p
        WHERE 
            p.OwnerUserId = tu.UserId
            AND p.ViewCount > (
                SELECT 
                    AVG(ViewCount)
                FROM 
                    Posts
            )
    ), 'No Popular Posts') AS PopularPostTitles,
    COALESCE((
        SELECT 
            STRING_AGG(DISTINCT c.Text, '; ')
        FROM 
            Comments c
        WHERE 
            c.UserId = tu.UserId
    ), 'No Comments') AS UserComments
FROM 
    TopUsers tu
ORDER BY 
    tu.TotalPosts DESC;
