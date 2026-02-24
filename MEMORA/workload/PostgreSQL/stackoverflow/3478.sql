WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
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
        TotalPosts, 
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserStats
),
PostHistoryAnalysis AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate,
        PH.PostHistoryTypeId,
        PH.UserId,
        PH.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12, 13)  
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalScore,
    PHA.PostId,
    PHA.Title,
    PHA.CreationDate,
    PHA.PostHistoryTypeId,
    PHA.UserDisplayName AS ActionBy,
    CASE 
        WHEN PHA.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN PHA.PostHistoryTypeId = 11 THEN 'Reopened'
        WHEN PHA.PostHistoryTypeId = 12 THEN 'Deleted'
        WHEN PHA.PostHistoryTypeId = 13 THEN 'Undeleted'
        ELSE 'Other'
    END AS ActionType
FROM 
    TopUsers TU
LEFT JOIN 
    PostHistoryAnalysis PHA ON TU.UserId = PHA.UserId
WHERE 
    TU.ScoreRank <= 10 
ORDER BY 
    TU.TotalScore DESC, 
    PHA.CreationDate DESC;