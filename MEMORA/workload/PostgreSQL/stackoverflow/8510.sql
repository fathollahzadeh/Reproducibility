WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    WHERE 
        U.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName,
        TotalPosts, TotalComments, TotalVotes, TotalScore,
        ActivityRank
    FROM 
        UserActivity
    WHERE 
        ActivityRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalComments,
    TU.TotalVotes,
    TU.TotalScore,
    COALESCE(BA.BadgeCount, 0) AS TotalBadges
FROM 
    TopUsers TU
LEFT JOIN (
    SELECT 
        UserId, COUNT(*) AS BadgeCount 
    FROM 
        Badges 
    WHERE 
        Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        UserId
) BA ON TU.UserId = BA.UserId
ORDER BY 
    TU.TotalScore DESC, TU.TotalPosts DESC;