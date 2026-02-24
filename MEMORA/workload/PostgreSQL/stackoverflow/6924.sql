
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.ViewCount ELSE 0 END) AS AnswerViewCount,
        SUM(CASE WHEN P.PostTypeId IN (1, 2) THEN P.Score ELSE 0 END) AS TotalScore
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
        QuestionCount,
        AnswerViewCount,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalScore DESC) AS Rank
    FROM 
        UserStats
    WHERE 
        Reputation >= 1000
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.BadgeCount,
    T.QuestionCount,
    T.AnswerViewCount,
    T.TotalScore,
    T.Rank,
    PH.CreationDate AS LastActivityDate,
    COUNT(Comment.Id) AS TotalComments
FROM 
    TopUsers T
LEFT JOIN 
    Posts P ON T.UserId = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId 
LEFT JOIN 
    Comments Comment ON P.Id = Comment.PostId
WHERE 
    T.Rank <= 10
GROUP BY 
    T.UserId, T.DisplayName, T.Reputation, T.BadgeCount, T.QuestionCount, T.AnswerViewCount, T.TotalScore, T.Rank, PH.CreationDate
ORDER BY 
    T.Rank;
