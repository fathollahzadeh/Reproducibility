WITH UserVoteStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        AVG(COALESCE(P.Score, 0)) AS AveragePostScore,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        (SELECT SUM(ViewCount) FROM Posts WHERE Tags LIKE '%' || T.TagName || '%') AS TotalViews
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 5
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId IN (4, 6) THEN PH.CreationDate END) AS LastEditDate,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS LastCloseDate,
        MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN PH.CreationDate END) AS LastReopenDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation AS UserReputation,
    COALESCE(UP.TotalUpVotes, 0) - COALESCE(UP.TotalDownVotes, 0) AS NetVotes,
    PT.TagName AS PostTag,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    PH.LastEditDate,
    PH.LastCloseDate,
    PH.LastReopenDate,
    (CASE 
        WHEN PH.LastCloseDate IS NOT NULL AND PH.LastReopenDate IS NULL THEN 'Closed'
        WHEN PH.LastReopenDate IS NOT NULL THEN 'Reopened'
        ELSE 'Active'
    END) AS PostStatus
FROM 
    Users U
JOIN 
    UserVoteStatistics UP ON U.Id = UP.UserId
JOIN 
    Posts P ON U.Id = P.OwnerUserId 
LEFT JOIN 
    PostHistorySummary PH ON P.Id = PH.PostId
LEFT JOIN 
    PopularTags PT ON PT.PostCount = (SELECT MAX(PostCount) FROM PopularTags)
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users) 
AND 
    PT.TotalViews > (SELECT AVG(TotalViews) FROM PopularTags)
ORDER BY 
    UserReputation DESC, NetVotes DESC, P.CreationDate DESC;
