WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(b.Class) AS TotalBadgeClass,
        AVG(COALESCE(c.Score, 0)) AS AvgCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.UpVotes, u.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalScore,
        AnswerCount,
        QuestionCount,
        TotalBadgeClass,
        AvgCommentScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Ranking
    FROM 
        UserStats
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    TotalScore,
    AnswerCount,
    QuestionCount,
    TotalBadgeClass,
    AvgCommentScore
FROM 
    TopUsers
WHERE 
    Ranking <= 10
ORDER BY 
    TotalScore DESC;
