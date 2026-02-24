WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(COALESCE(V.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        PT.Name AS PostTypeName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        PT.Name
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    U.TotalVotes,
    U.TotalViews,
    P.PostTypeName,
    P.PostCount AS TypePostCount,
    P.TotalViews AS TypeTotalViews,
    P.AverageScore,
    P.CommentCount
FROM 
    UserStats U
JOIN 
    PostStats P ON U.PostCount > 0
ORDER BY 
    U.Reputation DESC, P.PostTypeName;