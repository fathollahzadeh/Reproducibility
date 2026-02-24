WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(B.Count, 0)) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS Count
        FROM 
            Badges
        GROUP BY 
            UserId
    ) B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalVotes,
    TotalBadges
FROM 
    UserStats
ORDER BY 
    PostCount DESC, TotalVotes DESC
LIMIT 10;