
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0 
),
PostStatistics AS (
    SELECT 
        u.DisplayName,
        COUNT(rp.PostId) AS QuestionCount,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.AnswerCount) AS TotalAnswers,
        AVG(rp.CommentCount) AS AvgComments
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.rn <= 5 
    GROUP BY 
        u.DisplayName
),
TopUsers AS (
    SELECT 
        DisplayName,
        QuestionCount,
        TotalScore,
        TotalAnswers,
        AvgComments,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        PostStatistics
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    tu.QuestionCount,
    tu.TotalScore,
    tu.TotalAnswers,
    tu.AvgComments,
    tu.ScoreRank
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.DisplayName = u.DisplayName
WHERE 
    tu.ScoreRank <= 10 
ORDER BY 
    tu.ScoreRank;
