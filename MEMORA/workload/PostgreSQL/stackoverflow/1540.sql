
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounty,
        ActivityRank
    FROM 
        UserActivity
    WHERE 
        ActivityRank <= 10
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseCount,
        STRING_AGG(DISTINCT C.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS int) = C.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName AS User,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    COALESCE(CP.CloseCount, 0) AS CloseCount,
    COALESCE(CP.CloseReasons, 'No Close Reasons') AS CloseReasons,
    U.TotalBounty
FROM 
    TopUsers U
LEFT JOIN 
    ClosedPosts CP ON U.UserId = CP.PostId
ORDER BY 
    U.ActivityRank;
