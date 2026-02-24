
WITH RECURSIVE UserPostSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
), 
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.CreationDate,
        P.Title,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 DAY'
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        UPS.PostCount,
        UPS.QuestionCount,
        UPS.AnswerCount,
        UPS.TotalScore,
        RP.Title AS RecentPostTitle
    FROM 
        UserPostSummary UPS
    JOIN 
        (SELECT Id AS UserId, DisplayName FROM Users WHERE Reputation > 1000) U ON UPS.UserId = U.UserId
    LEFT JOIN 
        RecentPosts RP ON U.UserId = RP.OwnerUserId AND RP.rn = 1
    WHERE 
        UPS.TotalScore > 50
)

SELECT 
    TU.DisplayName,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalScore,
    COALESCE(TU.RecentPostTitle, 'No recent posts') AS RecentPostTitle,
    CASE 
        WHEN TU.TotalScore > 100 THEN 'High Scorer'
        WHEN TU.TotalScore BETWEEN 50 AND 100 THEN 'Medium Scorer'
        ELSE 'Low Scorer'
    END AS ScoreCategory
FROM 
    TopUsers TU
ORDER BY 
    TU.TotalScore DESC, 
    TU.DisplayName ASC;
