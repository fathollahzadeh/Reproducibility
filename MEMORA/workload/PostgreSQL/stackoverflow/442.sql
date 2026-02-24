
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostCount,
        COALESCE(SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END), 0) AS TotalScore,
        RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS UpvoteRank
    FROM 
        Users U 
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Upvotes,
        UA.Downvotes,
        UA.PostCount,
        UA.TotalScore,
        UA.UpvoteRank
    FROM 
        UserActivity UA
    WHERE 
        UA.PostCount > 5 AND UA.Upvotes > 10
),
RelevantTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(DISTINCT P.Id) > 10
)
SELECT 
    U.DisplayName AS TopUser,
    U.Upvotes,
    U.Downvotes,
    T.TagName,
    T.PostCount,
    CASE 
        WHEN U.Upvotes > U.Downvotes THEN 'Positive Engagement'
        WHEN U.Upvotes < U.Downvotes THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementType
FROM 
    TopUsers U
JOIN 
    RelevantTags T ON U.PostCount > T.PostCount
WHERE 
    U.UpvoteRank <= 10
ORDER BY 
    U.Upvotes DESC, T.PostCount DESC;
