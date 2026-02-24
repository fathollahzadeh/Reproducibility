
WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotesCount,
        DownVotesCount,
        TotalPosts,
        TotalComments,
        RANK() OVER (ORDER BY Reputation DESC, UpVotesCount DESC) AS UserRank
    FROM 
        UserScores
),
FilteredUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotesCount,
        DownVotesCount,
        TotalPosts,
        TotalComments
    FROM 
        RankedUsers
    WHERE 
        UserRank <= 10
)
SELECT 
    FU.DisplayName,
    FU.Reputation,
    FU.UpVotesCount,
    FU.DownVotesCount,
    FU.TotalPosts,
    FU.TotalComments,
    CASE 
        WHEN FU.Reputation >= 1000 THEN 'High Reputation'
        ELSE 'Moderate Reputation'
    END AS ReputationCategory,
    STRING_AGG(DISTINCT T.TagName, ', ') AS TagList
FROM 
    FilteredUsers FU
LEFT JOIN 
    Posts P ON FU.UserId = P.OwnerUserId
LEFT JOIN 
    LATERAL (SELECT UNNEST(string_to_array(P.Tags, ', ')) AS TagName) AS T ON true
GROUP BY 
    FU.UserId, FU.DisplayName, FU.Reputation, FU.UpVotesCount, FU.DownVotesCount, FU.TotalPosts, FU.TotalComments
ORDER BY 
    FU.Reputation DESC;
