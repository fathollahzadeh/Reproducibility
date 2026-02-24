
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        Upvotes,
        Downvotes,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS RankScore,
        RANK() OVER (ORDER BY Upvotes DESC) AS RankUpvotes
    FROM UserEngagement
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.Upvotes,
    U.Downvotes,
    U.TotalScore,
    CASE 
        WHEN U.RankScore <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorStatus,
    COALESCE((
        SELECT STRING_AGG(DISTINCT T.TagName, ', ')
        FROM Posts P2 
        JOIN Tags T ON P2.Tags LIKE '%' || T.TagName || '%'
        WHERE P2.OwnerUserId = U.UserId
    ), 'No Tags') AS UserTags
FROM TopUsers U
WHERE U.RankUpvotes = 1 OR U.RankScore <= 5
ORDER BY U.TotalScore DESC, U.Upvotes DESC;
