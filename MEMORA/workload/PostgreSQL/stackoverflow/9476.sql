
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(DISTINCT P.Id) AS TotalPosts, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(P.Score) AS TotalScore,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        QuestionsCount, 
        AnswersCount, 
        TotalScore, 
        Reputation, 
        UserRank
    FROM 
        UserActivity
    WHERE 
        UserRank <= 10
)

SELECT 
    T.DisplayName, 
    T.TotalPosts, 
    T.QuestionsCount, 
    T.AnswersCount, 
    T.TotalScore, 
    T.Reputation, 
    (SELECT ARRAY(SELECT DISTINCT TagName FROM Tags WHERE TagName IN 
        (
            SELECT 
                unnest(string_to_array(P.Tags, '>')) 
            FROM 
                Posts P 
            WHERE 
                P.OwnerUserId = T.UserId
        )
    )) AS ActiveTags,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = T.UserId) AS TotalBadges
FROM 
    TopUsers T
ORDER BY 
    T.TotalScore DESC;
