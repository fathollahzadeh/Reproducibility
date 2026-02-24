
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        TotalPosts,
        Questions,
        Answers,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC, Reputation DESC) AS Rank
    FROM 
        UserReputation
    WHERE 
        TotalPosts > 5
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS Author,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName, P.ViewCount, P.Score
),
UserPostDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.Score,
        COALESCE(RP.CommentCount, 0) AS CommentCount,
        RANK() OVER (PARTITION BY U.Id ORDER BY RP.CreationDate DESC) AS PostRank
    FROM 
        Users U
    JOIN 
        RecentPosts RP ON U.DisplayName = RP.Author
)
SELECT 
    UPD.UserId,
    UPD.DisplayName,
    COALESCE(SUM(CASE WHEN UPD.PostRank = 1 THEN UPD.ViewCount END), 0) AS MostViewedPostCount,
    COALESCE(MIN(UPD.Score), 0) AS LowestScore,
    COALESCE(AVG(UPD.CommentCount), 0) AS AvgComments,
    MAX(TAU.Reputation) AS Reputation
FROM 
    UserPostDetails UPD
JOIN 
    TopActiveUsers TAU ON UPD.UserId = TAU.UserId
GROUP BY 
    UPD.UserId, UPD.DisplayName
HAVING 
    COUNT(UPD.PostId) >= 3
ORDER BY 
    MAX(TAU.Reputation) DESC, MostViewedPostCount DESC;
