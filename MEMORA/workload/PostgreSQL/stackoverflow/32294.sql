WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowNum
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, U.DisplayName, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId
)
, PostVoteData AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes V
    GROUP BY V.PostId
)
SELECT 
    RP.PostId, 
    RP.Title, 
    RP.CreationDate, 
    RP.Score, 
    RP.ViewCount, 
    RP.OwnerDisplayName, 
    COALESCE(PVD.UpVotes, 0) AS UpVotes,
    COALESCE(PVD.DownVotes, 0) AS DownVotes,
    RP.CommentCount,
    CASE 
        WHEN RP.Score > 0 THEN 'Popular'
        WHEN RP.Score = 0 THEN 'Neutral'
        ELSE 'Unpopular'
    END AS PopularityCategory,
    (SELECT COUNT(*) FROM Posts P WHERE P.ParentId = RP.PostId) AS AnswerCount
FROM RecentPosts RP
LEFT JOIN PostVoteData PVD ON RP.PostId = PVD.PostId
WHERE RP.RowNum = 1
ORDER BY RP.Score DESC, RP.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;