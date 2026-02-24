WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(V.BountyAmount) AS AvgBounty,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8  
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ClosedPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS ClosedPostCount
    FROM 
        Posts P
    INNER JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10  
    GROUP BY 
        P.OwnerUserId
),
TopClosedPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(CP.ClosedPostCount, 0) AS ClosedPostCount
    FROM 
        Users U
    LEFT JOIN 
        ClosedPosts CP ON U.Id = CP.OwnerUserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.QuestionCount,
    US.AnswerCount,
    US.AvgBounty,
    TCP.ClosedPostCount,
    US.UserRank
FROM 
    UserStats US
LEFT JOIN 
    TopClosedPosts TCP ON US.UserId = TCP.UserId
WHERE 
    US.Reputation > 1000  
ORDER BY 
    US.UserRank;