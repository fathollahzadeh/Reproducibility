WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COALESCE(MAX(P.ViewCount), 0) AS MaxViewCount
    FROM 
        Users U
        LEFT JOIN Votes V ON U.Id = V.UserId
        LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id
),
FilteredPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
)

SELECT 
    UVD.DisplayName,
    UVD.Reputation,
    UVD.TotalVotes,
    UVD.UpVotes,
    UVD.DownVotes,
    FP.PostId,
    FP.Title,
    FP.Score,
    FP.ViewCount,
    CASE 
        WHEN FP.Rank = 1 THEN 'Most Viewed'
        WHEN FP.Rank <= 5 THEN 'Top 5 Viewed'
        ELSE 'Less Viewed'
    END AS ViewRank,
    PH.Comment,
    PH.CreationDate AS HistoryCreationDate,
    PH.UserDisplayName AS Editor,
    CASE 
        WHEN PH.PostHistoryTypeId IS NOT NULL THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus,
    PH.RevisionGUID,
    (SELECT COUNT(*) 
     FROM Votes V2 
     WHERE V2.PostId = FP.PostId 
       AND V2.VoteTypeId = 1) AS AcceptedAnswers
FROM 
    UserVoteStats UVD
    JOIN FilteredPosts FP ON FP.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = UVD.UserId)
    LEFT JOIN PostHistory PH ON FP.PostId = PH.PostId 
                               AND PH.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
WHERE 
    UVD.TotalVotes > 10 
    AND (UVD.Reputation > 100 OR UVD.TotalPosts > 5)
ORDER BY 
    UVD.Reputation DESC,
    FP.ViewCount DESC
LIMIT 50;