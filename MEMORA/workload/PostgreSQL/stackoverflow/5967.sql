WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(B.Class) AS BadgeScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 50
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        CommentCount,
        BadgeScore,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.CommentCount,
    U.BadgeScore,
    PH.CreationDate,
    P.Title,
    PH.Comment
FROM 
    TopUsers U
INNER JOIN 
    PostHistory PH ON U.UserId = PH.UserId
INNER JOIN 
    Posts P ON PH.PostId = P.Id
WHERE 
    U.Rank <= 10
ORDER BY 
    U.Rank, PH.CreationDate DESC;
