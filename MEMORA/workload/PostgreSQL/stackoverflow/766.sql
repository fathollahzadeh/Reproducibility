
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(vote.VoteCount, 0) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId IN (2, 3) 
        GROUP BY 
            PostId
    ) vote ON p.Id = vote.PostId
    WHERE 
        p.PostTypeId = 1 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
UserPostStats AS (
    SELECT 
        u.UserId,
        COUNT(ps.PostId) AS TotalPosts,
        SUM(ps.VoteCount) AS TotalVotes,
        AVG(ps.Score) AS AverageScore
    FROM 
        TopUsers u
    LEFT JOIN 
        PostStats ps ON u.UserId = ps.OwnerUserId
    GROUP BY 
        u.UserId
    HAVING 
        COUNT(ps.PostId) > 0
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    ups.TotalPosts,
    ups.TotalVotes,
    ups.AverageScore,
    tu.UserRank,
    CASE 
        WHEN ups.AverageScore IS NULL THEN 'No Score Yet'
        WHEN ups.AverageScore > 0 THEN 'Positive Score'
        ELSE 'Negative Score'
    END AS ScoreStatus
FROM 
    TopUsers tu
JOIN 
    UserPostStats ups ON tu.UserId = ups.UserId
ORDER BY 
    ups.TotalVotes DESC, 
    ups.TotalPosts DESC;
