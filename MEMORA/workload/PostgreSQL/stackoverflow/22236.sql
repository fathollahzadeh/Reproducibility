
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(P.Id) DESC) AS Rank
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    U.TotalPosts,
    U.TotalComments,
    U.UpVotes,
    U.DownVotes,
    PT.TagName AS PopularTag,
    PT.PostCount AS TagPostCount
FROM 
    UserStatistics U
LEFT JOIN 
    PopularTags PT ON U.TotalPosts > 0 AND 
                     (U.TotalPosts = (SELECT MAX(TotalPosts) FROM UserStatistics WHERE TotalPosts > 0) OR
                     U.Reputation = (SELECT MAX(Reputation) FROM UserStatistics WHERE TotalPosts > 0))
WHERE 
    (U.Reputation > 100 OR U.TotalPosts > 10)
ORDER BY 
    U.Reputation DESC, 
    PT.TagName ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
