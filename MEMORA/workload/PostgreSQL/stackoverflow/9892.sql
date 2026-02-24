
WITH TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
        COUNT(b.Id) AS TotalBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM
        Users u
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    WHERE
        u.CreationDate < '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year' 
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > '2024-10-01 12:34:56'::timestamp - INTERVAL '6 months' 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        u.DisplayName AS UserDisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(a.AnswerCount) AS AnswersGiven,
        SUM(a.Score) AS TotalPostScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            Id, 
            AnswerCount, 
            Score 
         FROM 
            Posts 
         WHERE 
            PostTypeId = 2) a ON p.Id = a.Id
    GROUP BY 
        u.DisplayName
)
SELECT 
    tu.DisplayName,
    tu.TotalVotes,
    tu.TotalBadges,
    tu.AvgReputation,
    ap.Title AS ActivePostTitle,
    ap.TotalComments AS ActivePostComments,
    ap.TotalVotes AS ActivePostVotes,
    ups.PostsCreated,
    ups.AnswersGiven,
    ups.TotalPostScore
FROM 
    TopUsers tu
JOIN 
    ActivePosts ap ON tu.UserId = ap.OwnerUserId
JOIN 
    UserPostStats ups ON tu.DisplayName = ups.UserDisplayName
ORDER BY 
    tu.TotalVotes DESC, 
    ups.PostsCreated DESC
LIMIT 10;
