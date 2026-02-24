
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT DISTINCT unnest(regexp_split_to_array(P.Tags, '[><]')) AS TagName) AS T ON TRUE
    WHERE 
        P.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AcceptedAnswerId
)
SELECT 
    UEng.UserId,
    UEng.DisplayName,
    UEng.TotalPosts,
    UEng.TotalComments,
    UEng.TotalBounty,
    UEng.TotalUpvotes,
    UEng.TotalDownvotes,
    PA.PostId,
    PA.Title,
    PA.Score,
    PA.ViewCount,
    PA.AcceptedAnswerId,
    PA.Tags
FROM 
    UserEngagement UEng
JOIN 
    PostAnalytics PA ON UEng.UserId = PA.AcceptedAnswerId
ORDER BY 
    UEng.TotalUpvotes DESC, UEng.TotalPosts DESC, PA.Score DESC
LIMIT 100;
