WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END) AS QuestionsAnswered,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        QuestionsAnswered,
        TotalViews,
        AvgScore,
        RANK() OVER (ORDER BY Reputation DESC) AS RankByReputation,
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews
    FROM 
        UserStats 
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.BadgeCount,
    T.QuestionsAnswered,
    T.TotalViews,
    T.AvgScore,
    CASE 
        WHEN T.RankByReputation <= 10 THEN 'Top 10 by Reputation'
        WHEN T.RankByViews <= 10 THEN 'Top 10 by Views'
        ELSE 'Below Top 10'
    END AS RankCategory
FROM 
    TopUsers T
WHERE 
    T.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    T.Reputation DESC, T.TotalViews DESC;

