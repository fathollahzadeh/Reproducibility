
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN COALESCE(V.VoteTypeId, 0) = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN COALESCE(V.VoteTypeId, 0) = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(P.ViewCount, 0)) DESC) AS ViewRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostWithMaxVotes AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(V.Id) AS VoteCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY COUNT(V.Id) DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.TotalViews,
    U.UpVotes,
    U.DownVotes,
    P.Title AS TopPostTitle,
    P.CreationDate AS TopPostDate,
    P.VoteCount AS TopPostVoteCount,
    U.ViewRank
FROM 
    UserStatistics U
LEFT JOIN 
    PostWithMaxVotes P ON U.UserId = P.OwnerUserId AND P.PostRank = 1
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, U.TotalViews DESC
LIMIT 10 OFFSET 0;
