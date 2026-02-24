
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        RANK() OVER (ORDER BY SUM(COALESCE(P.Score, 0)) DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9
    GROUP BY U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS TagPostCount
    FROM 
        Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY T.TagName
    HAVING COUNT(DISTINCT P.Id) > 5
),
UserSummary AS (
    SELECT 
        U.DisplayName,
        U.CreationDate,
        UR.TotalBounty,
        UR.TotalPosts,
        UR.TotalScore,
        PT.TagPostCount
    FROM 
        Users U
    JOIN UserReputation UR ON U.Id = UR.UserId
    LEFT JOIN PopularTags PT ON PT.TagPostCount = (
        SELECT MAX(TagPostCount) FROM PopularTags
    )
)
SELECT 
    US.DisplayName,
    EXTRACT(YEAR FROM CURRENT_DATE - US.CreationDate) AS AccountAge,
    US.TotalBounty,
    US.TotalPosts,
    US.TotalScore,
    COALESCE(pt.TagName, 'No Popular Tags') AS MostPopularTag
FROM 
    UserSummary US
LEFT JOIN PopularTags pt ON pt.TagPostCount = US.TagPostCount
WHERE 
    US.TotalScore > 100
ORDER BY 
    AccountAge DESC, US.TotalBounty DESC
LIMIT 10;
