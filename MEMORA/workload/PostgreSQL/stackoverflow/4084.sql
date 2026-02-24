
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS ClosedPosts,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenedPosts
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserStatistics AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        Upvotes,
        Downvotes,
        ClosedPosts,
        ReopenedPosts,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN Reputation > 5000 THEN 1 ELSE 0 END ORDER BY PostCount DESC) AS HighReputationPostRank
    FROM UserReputation
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(U.PostCount, 0) AS TotalPosts,
    COALESCE(U.Upvotes - U.Downvotes, 0) AS NetVotes,
    U.ReopenedPosts,
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM Posts P 
     JOIN UNNEST(string_to_array(P.Tags, ',')) AS Tag ON TRUE
     JOIN Tags T ON Tag = T.TagName
     WHERE P.OwnerUserId = U.UserId) AS TagsUsed,
    CASE 
        WHEN U.Reputation > 10000 THEN 'Top Contributor' 
        WHEN U.Reputation > 5000 THEN 'Experienced' 
        ELSE 'New User' 
    END AS UserCategory
FROM 
    UserStatistics U
WHERE 
    U.ReputationRank <= 10 
    OR U.HighReputationPostRank <= 5 
ORDER BY 
    U.Reputation DESC, U.DisplayName
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
