WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(V.BountyAmount) AS TotalBounty,
        AVG(CASE WHEN C.Score IS NOT NULL THEN C.Score ELSE 0 END) AS AvgCommentScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
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
        TotalBounty,
        AvgCommentScore,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    UserId, 
    DisplayName,
    Reputation,
    PostCount,
    AnswerCount,
    QuestionCount,
    TotalBounty,
    AvgCommentScore
FROM 
    TopUsers
WHERE 
    Rank <= 10;
