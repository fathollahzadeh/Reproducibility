WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS TagName,
            Id AS PostId
        FROM Posts
        WHERE Tags IS NOT NULL
    ) t ON p.Id = t.PostId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        TotalScore,
        Tags,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewsRank,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserPostStats
),
UserRankings AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        TotalScore,
        Tags,
        ViewsRank,
        ReputationRank,
        CASE
            WHEN ViewsRank <= 10 THEN 'Top 10 by Views'
            WHEN ReputationRank <= 10 THEN 'Top 10 by Reputation'
            ELSE 'Other'
        END AS RankingCategory
    FROM TopUsers
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TotalScore,
    Tags,
    RankingCategory
FROM UserRankings
WHERE RankingCategory != 'Other'
ORDER BY TotalViews DESC, Reputation DESC;
