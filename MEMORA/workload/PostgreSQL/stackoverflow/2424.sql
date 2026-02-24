WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId AND V.VoteTypeId IN (8, 9) 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounties,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, PostCount DESC) AS UserRank
    FROM 
        UserStats
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.ClosedDate IS NOT NULL
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalBounties,
    CP.Title AS ClosedPostTitle,
    CP.CloseCount,
    CP.ReopenCount,
    CASE 
        WHEN CP.CloseCount IS NULL THEN 'No closings'
        WHEN CP.CloseCount > CP.ReopenCount THEN 'More Closed'
        ELSE 'More Reopened'
    END AS CloseStatus
FROM 
    TopUsers U
LEFT JOIN 
    ClosedPosts CP ON U.UserId = (SELECT OwnerUserId FROM Posts WHERE Title = CP.Title LIMIT 1)
WHERE 
    U.UserRank <= 10
ORDER BY 
    U.Reputation DESC;