
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(NULLIF(SUM(V.BountyAmount), 0), 0) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        COALESCE((
            SELECT COUNT(*)
            FROM Comments C
            WHERE C.PostId = P.Id
        ), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS RecentActivity
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.Questions,
    US.Answers,
    US.TotalBounties,
    PT.Title,
    PT.CreationDate AS PostCreationDate,
    PT.Score,
    PT.ViewCount,
    PT.CommentCount,
    CASE 
        WHEN PT.RecentActivity <= 10 THEN 'Active' 
        ELSE 'Less Active' 
    END AS PostActivityStatus
FROM 
    UserStats US
LEFT JOIN 
    PostActivity PT ON US.DisplayName = PT.OwnerName
WHERE 
    US.Reputation > 1000
ORDER BY 
    US.TotalPosts DESC, US.Reputation DESC
LIMIT 50 OFFSET 0;
