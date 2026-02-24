
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId NOT IN (1, 2) THEN 1 ELSE 0 END) AS OtherPostTypes,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(u.Reputation) OVER () AS AvgReputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
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
        OtherPostTypes,
        TotalBounty,
        AvgReputation,
        UserRank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0 
        AND UserRank <= 10
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(DISTINCT p.Id) AS TotalQuestions, 
        AVG(p.Score) AS AvgScore, 
        MAX(p.ViewCount) AS MaxViews
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserQuestionRankings AS (
    SELECT 
        u.UserId, 
        u.DisplayName, 
        qs.TotalQuestions, 
        qs.AvgScore,
        qs.MaxViews,
        RANK() OVER (ORDER BY qs.TotalQuestions DESC) AS QuestionRank
    FROM 
        TopUsers u
    LEFT JOIN 
        QuestionStats qs ON u.UserId = qs.OwnerUserId
),
BountyAnalysis AS (
    SELECT 
        u.DisplayName,
        COUNT(v.Id) AS TotalBountyVotes
    FROM 
        Users u
    INNER JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.DisplayName
)
SELECT 
    uqr.DisplayName AS User,
    uqr.TotalQuestions,
    COALESCE(uqr.AvgScore, 0) AS AverageScore,
    COALESCE(uqr.MaxViews, 0) AS MaximumViews,
    COALESCE(ban.TotalBountyVotes, 0) AS TotalBountyVotes,
    uqr.QuestionRank,
    CASE 
        WHEN uqr.TotalQuestions > 100 THEN 'Expert'
        WHEN uqr.TotalQuestions BETWEEN 50 AND 100 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserCategory
FROM 
    UserQuestionRankings uqr
LEFT JOIN 
    BountyAnalysis ban ON uqr.DisplayName = ban.DisplayName
ORDER BY 
    uqr.QuestionRank
