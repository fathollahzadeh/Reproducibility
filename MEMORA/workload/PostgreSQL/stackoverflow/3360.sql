
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY SUM(COALESCE(P.ViewCount, 0)) DESC) AS ViewRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(C.CreationDate) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY P.ViewCount DESC) AS PopularityRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount
    HAVING 
        COUNT(C.CreationDate) > 5 OR P.Score > 10
),
PostHistoryAggregates AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(PH.Id) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    P.Title AS PostTitle,
    P.ViewCount AS PostViewCount,
    PH.EditCount,
    PS.TotalUpVotes,
    PS.TotalDownVotes,
    PS.CommentCount,
    PS.PopularityRank
FROM 
    UserStats U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId
JOIN 
    PostHistoryAggregates PH ON P.Id = PH.PostId
LEFT JOIN 
    PopularPosts PS ON P.Id = PS.PostId
WHERE 
    U.Reputation > 1000
AND 
    (PS.TotalUpVotes - PS.TotalDownVotes) > 5
ORDER BY 
    U.Reputation DESC, PS.PopularityRank ASC;
