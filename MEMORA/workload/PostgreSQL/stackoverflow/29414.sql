WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS TagUsageCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%,', T.TagName, ',%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(DISTINCT P.Id) > 5 
),
PostsRanked AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
)
SELECT 
    U.DisplayName,
    UE.TotalPosts,
    UE.TotalComments,
    UE.TotalBounty,
    UE.UpVotes,
    UE.DownVotes,
    PT.TagName,
    PR.PostId,
    PR.Title,
    PR.Score,
    PR.ViewCount
FROM 
    UserEngagement UE
JOIN 
    PopularTags PT ON UE.TotalPosts > 10
JOIN 
    PostsRanked PR ON PR.Rank <= 10 
LEFT JOIN 
    Users U ON U.Id = UE.UserId
WHERE 
    UE.UpVotes > 20
ORDER BY 
    UE.UpVotes DESC, PR.Score DESC;