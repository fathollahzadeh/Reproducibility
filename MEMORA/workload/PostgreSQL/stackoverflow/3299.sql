WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM
        Users U
),
PostSummary AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore
    FROM
        Posts P
    GROUP BY
        P.OwnerUserId
),
CloseReasonCounts AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS CloseReasonVotes
    FROM
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)
    GROUP BY
        PH.UserId
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.Questions, 0) AS Questions,
    COALESCE(PS.Answers, 0) AS Answers,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    COALESCE(CR.CloseReasonVotes, 0) AS CloseReasonVotes
FROM 
    UserReputation UR
LEFT JOIN 
    PostSummary PS ON UR.UserId = PS.OwnerUserId
LEFT JOIN 
    CloseReasonCounts CR ON UR.UserId = CR.UserId
WHERE 
    UR.ReputationRank <= 50
ORDER BY 
    UR.Reputation DESC, UR.DisplayName;
