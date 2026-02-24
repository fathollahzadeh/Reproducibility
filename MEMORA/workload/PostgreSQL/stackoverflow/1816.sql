WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopBadgedUsers AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
    HAVING 
        COUNT(b.Id) > 5
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(ubs.TotalPosts, 0) AS TotalPosts,
        COALESCE(c.TotalComments, 0) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        UserPostStats ubs ON u.Id = ubs.UserId
    LEFT JOIN 
        (SELECT 
            c.UserId,
            COUNT(c.Id) AS TotalComments
         FROM 
            Comments c
         GROUP BY 
            c.UserId) c ON u.Id = c.UserId
    WHERE 
        u.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    a.UserId,
    a.DisplayName,
    a.Reputation,
    a.CreationDate,
    a.TotalPosts,
    a.TotalComments,
    COALESCE(tbu.BadgeCount, 0) AS BadgeCount,
    COALESCE(tbu.BadgeNames, 'No Badges') AS BadgeNames,
    CASE 
        WHEN a.TotalPosts > 10 THEN 'Active Contributor'
        WHEN a.TotalComments > 5 THEN 'Engaged User'
        ELSE 'Newbie'
    END AS UserType,
    ROW_NUMBER() OVER (ORDER BY a.Reputation DESC) AS UserRank
FROM 
    ActiveUsers a
LEFT JOIN 
    TopBadgedUsers tbu ON a.UserId = tbu.UserId
ORDER BY 
    a.TotalPosts DESC, a.Reputation DESC
LIMIT 20;