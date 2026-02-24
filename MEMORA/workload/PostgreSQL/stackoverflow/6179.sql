WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS TotalPosts, 
        COUNT(DISTINCT C.Id) AS TotalComments, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes, 
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes 
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.ViewCount, 
        P.Score, 
        PT.Name AS PostType, 
        T.TagName
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Tags T ON P.Tags ILIKE '%' || T.TagName || '%'
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PD.PostId, 
        PD.Title, 
        PD.CreationDate, 
        PD.ViewCount, 
        PD.Score, 
        PD.PostType, 
        ROW_NUMBER() OVER (PARTITION BY PD.PostType ORDER BY PD.Score DESC) AS Rank
    FROM 
        PostDetails PD
)
SELECT 
    UM.UserId, 
    UM.Reputation, 
    UM.TotalPosts, 
    UM.TotalComments, 
    UM.TotalUpvotes, 
    UM.TotalDownvotes, 
    TP.Title AS TopPostTitle, 
    TP.ViewCount AS TopPostViews, 
    TP.Score AS TopPostScore
FROM 
    UserMetrics UM
LEFT JOIN 
    TopPosts TP ON UM.TotalPosts > 0 AND TP.Rank = 1
ORDER BY 
    UM.Reputation DESC, 
    UM.TotalPosts DESC;