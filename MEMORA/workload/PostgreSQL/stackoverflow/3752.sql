WITH UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        B.Class, 
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, B.Class
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgPostScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        P.OwnerUserId
),
UserVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    COALESCE(PS.TotalPosts, 0) AS PostsInLastYear,
    COALESCE(PS.TotalViews, 0) AS TotalViews,
    COALESCE(PS.AvgPostScore, 0) AS AverageScore,
    COALESCE(UV.VoteCount, 0) AS TotalVotes,
    COALESCE(UV.UpVotes, 0) AS TotalUpVotes,
    COALESCE(UV.DownVotes, 0) AS TotalDownVotes
FROM 
    Users U
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostStatistics PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    UserVotes UV ON U.Id = UV.UserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    TotalViews DESC, 
    U.DisplayName ASC
LIMIT 50;