WITH RECURSIVE UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(Id) AS PostCount
    FROM 
        Posts
    WHERE 
        CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '1 year'
    GROUP BY 
        OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COALESCE(UPC.PostCount, 0) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN 
        UserPostCounts UPC ON U.Id = UPC.OwnerUserId
    WHERE 
        U.Reputation > (
            SELECT AVG(Reputation) FROM Users
        )
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowNum
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '3 days'
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.TotalPosts,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    RP.ViewCount AS RecentPostViews,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = T.Id) AND V.VoteTypeId = 2
    ) AS TotalUpvotes,
    (SELECT COUNT(*) 
     FROM Comments C 
     WHERE C.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = T.Id)
    ) AS TotalComments
FROM 
    TopUsers T
LEFT JOIN 
    RecentPosts RP ON T.Id = RP.OwnerUserId AND RP.RowNum = 1
WHERE 
    EXISTS (
      SELECT 1 
      FROM Badges B 
      WHERE B.UserId = T.Id AND B.Class = 1
    )
ORDER BY 
    T.Reputation DESC, RecentPostViews DESC
LIMIT 10;