
WITH UserVotes AS (
    SELECT 
        U.Id AS UserId, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT POST.Id) AS PostsCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts POST ON V.PostId = POST.Id
    WHERE U.Reputation > 1000
    GROUP BY U.Id
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        LEAD(P.CreationDate) OVER (ORDER BY P.CreationDate DESC) AS NextCreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rn
    FROM Posts P
    WHERE P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
),
ClosedPosts AS (
    SELECT 
        PH.PostId, 
        COUNT(*) AS CloseCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName, 
    UV.UpVotesCount, 
    UV.DownVotesCount, 
    RP.Title AS RecentPostTitle,
    RP.Score AS RecentPostScore,
    COALESCE(CP.CloseCount, 0) AS PostCloseCount,
    CASE 
        WHEN UV.UpVotesCount - UV.DownVotesCount > 100 THEN 'Highly Active'
        WHEN UV.UpVotesCount - UV.DownVotesCount BETWEEN 50 AND 100 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
FROM UserVotes UV
JOIN Users U ON U.Id = UV.UserId
LEFT JOIN RecentPosts RP ON RP.Rn = 1 
LEFT JOIN ClosedPosts CP ON CP.PostId = RP.PostId
LEFT JOIN Posts P ON P.OwnerUserId = U.Id
LEFT JOIN UNNEST(STRING_TO_ARRAY(P.Tags, ',')) AS T(TagName) ON TRUE
WHERE UV.PostsCount > 5
GROUP BY U.DisplayName, UV.UpVotesCount, UV.DownVotesCount, RP.Title, RP.Score, CP.CloseCount
HAVING COUNT(DISTINCT P.Id) > 2
ORDER BY ActivityLevel DESC, UV.UpVotesCount DESC;
