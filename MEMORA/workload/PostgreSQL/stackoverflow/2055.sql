
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS PostsCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounty,
        PostsCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
    WHERE 
        PostsCount > 10
), 
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TagCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 5
), 
PostComments AS (
    SELECT 
        C.PostId,
        C.UserId,
        C.Text,
        RANK() OVER (PARTITION BY C.PostId ORDER BY C.CreationDate DESC) AS CommentRank
    FROM 
        Comments C
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalBounty,
    T.TagName,
    PC.Text AS RecentComment,
    PC.CommentRank
FROM 
    TopUsers U
LEFT JOIN 
    PopularTags T ON T.TagCount > 10
LEFT JOIN 
    PostComments PC ON U.UserId = PC.UserId AND PC.CommentRank = 1
WHERE 
    U.ReputationRank <= 20
ORDER BY 
    U.Reputation DESC, U.DisplayName ASC
FETCH FIRST 50 ROWS ONLY;
