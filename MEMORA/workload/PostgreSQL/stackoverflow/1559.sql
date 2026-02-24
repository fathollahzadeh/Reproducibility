
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank,
        P.OwnerUserId
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
), 
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        COALESCE(PH.Comment, 'No Comment') AS UserComment
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    U.DisplayName,
    U.Reputation,
    US.TotalPosts,
    US.AcceptedAnswers,
    R.PostId,
    R.Title,
    R.Score,
    R.ViewCount,
    COALESCE(PH.UserComment, 'No recent activity') AS RecentActivityComment
FROM 
    Users U
JOIN 
    UserStats US ON U.Id = US.UserId
LEFT JOIN 
    RankedPosts R ON U.Id = R.OwnerUserId AND R.PostRank <= 10
LEFT JOIN 
    RecentPostHistory PH ON R.PostId = PH.PostId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, R.Score DESC NULLS LAST;
