WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
TagStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.Id, T.TagName
)
SELECT 
    US.UserId,
    US.Reputation,
    US.Views,
    US.UpVotes,
    US.DownVotes,
    US.TotalPosts,
    US.TotalComments,
    US.TotalBounty,
    TS.TagName,
    TS.PostCount,
    TS.TotalViews
FROM 
    UserStats US
JOIN 
    TagStats TS ON US.TotalPosts > 0
ORDER BY 
    US.Reputation DESC, TS.PostCount DESC
LIMIT 100;