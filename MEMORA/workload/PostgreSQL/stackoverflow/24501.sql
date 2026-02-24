
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    WHERE 
        u.Reputation > 1000  
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalBounties,
        RANK() OVER (ORDER BY TotalPosts DESC, Reputation DESC) AS PostRank
    FROM 
        UserStats
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS QuestionCount,
        AVG(p.Score) AS AvgScore,
        MAX(p.ViewCount) AS MaxViews,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(p.Tags, ',')) AS Tag ON true
    JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM Tag)
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    QS.QuestionCount,
    QS.AvgScore,
    QS.MaxViews,
    QS.TagsUsed,
    COALESCE(u.TotalBounties, 0) AS TotalBounties
FROM 
    TopUsers u
LEFT JOIN 
    QuestionStats QS ON u.UserId = QS.OwnerUserId
WHERE 
    u.PostRank <= 10 
ORDER BY 
    u.PostRank;
