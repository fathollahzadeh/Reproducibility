WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000 
        AND U.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.TotalBounty,
    UA.UpVotes,
    UA.DownVotes,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    UA.ActivityRank
FROM 
    UserActivity UA
LEFT JOIN 
    RecentPosts RP ON UA.UserId = RP.OwnerUserId AND RP.PostRank = 1
WHERE 
    UA.ActivityRank <= 10
ORDER BY 
    UA.ActivityRank;