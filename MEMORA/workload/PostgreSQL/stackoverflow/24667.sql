WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(V.Id) AS VoteCount,
        AVG(COALESCE(V.BountyAmount, 0)) AS AvgBounty
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2  
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title
    HAVING 
        COUNT(V.Id) > 5  
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(PH.Id) AS ClosureCount,
        MAX(PH.CreationDate) AS LastClosed
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        P.Id
    HAVING 
        COUNT(PH.Id) > 1  
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    UP.QuestionsAsked,
    UP.AnswersGiven,
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    PP.VoteCount,
    PP.AvgBounty,
    CP.ClosureCount,
    CP.LastClosed
FROM 
    UserPostStats UP
JOIN 
    RankedPosts RP ON UP.UserId = RP.OwnerUserId AND RP.Rank = 1  
LEFT JOIN 
    PopularPosts PP ON RP.PostId = PP.PostId
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    (UP.QuestionsAsked > 2 OR UP.AnswersGiven > 5) 
ORDER BY 
    UP.DisplayName, PP.VoteCount DESC NULLS LAST, RP.CreationDate DESC;