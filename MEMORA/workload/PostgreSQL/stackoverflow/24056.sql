
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount END, 0)) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    WHERE 
        U.CreationDate < (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
    GROUP BY 
        U.Id, U.DisplayName
), PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C) AS CommentCount,
        COALESCE(SUM(B.Class), 0) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    WHERE 
        P.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
), RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        PV.PostId,
        PV.Title,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY PV.CreationDate DESC) AS RecentPostRank
    FROM 
        UserActivity UA
    JOIN 
        PostStatistics PV ON UA.TotalPosts > 0
    JOIN 
        Users U ON UA.UserId = U.Id
)
SELECT 
    RA.UserId,
    RA.DisplayName,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.BadgeCount,
    COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = PS.PostId AND V.VoteTypeId = 2), 0) AS TotalUpvotes,
    COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = PS.PostId AND V.VoteTypeId = 3), 0) AS TotalDownvotes
FROM 
    RecentActivity RA
JOIN 
    PostStatistics PS ON RA.PostId = PS.PostId
WHERE 
    RA.RecentPostRank = 1
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 10;
