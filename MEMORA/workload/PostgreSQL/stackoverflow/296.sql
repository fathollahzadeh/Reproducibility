WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(vt.VoteValue), 0) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
             PostId,
             SUM(CASE WHEN VoteTypeId = 2 THEN 1 
                      WHEN VoteTypeId = 3 THEN -1 
                      ELSE 0 END) AS VoteValue
         FROM 
             Votes 
         GROUP BY 
             PostId
        ) vt ON p.Id = vt.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalVotes,
        ROW_NUMBER() OVER (ORDER BY TotalVotes DESC) AS Rank
    FROM 
        UserPostStats
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.TotalVotes,
    CASE 
        WHEN t.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType,
    COALESCE(
        (SELECT 
             STRING_AGG(b.Name, ', ') 
         FROM 
             Badges b 
         WHERE 
             b.UserId = u.Id), 
         'No Badges'
    ) AS Badges,
    (SELECT 
         COUNT(c.Id)
     FROM 
         Comments c 
     WHERE 
         c.UserId = u.Id
    ) AS TotalComments
FROM 
    TopUsers t
JOIN 
    Users u ON t.UserId = u.Id
WHERE 
    u.Reputation > 100 
ORDER BY 
    TotalVotes DESC, 
    u.CreationDate ASC;
