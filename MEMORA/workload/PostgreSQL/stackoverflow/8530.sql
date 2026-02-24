
WITH RecentPosts AS (
    SELECT P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId, U.DisplayName AS OwnerDisplayName
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
),
VoteStatistics AS (
    SELECT PostId, COUNT(*) AS VoteCount, 
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY PostId
),
PostWithStatistics AS (
    SELECT RP.Title, RP.CreationDate, RP.Score, RP.ViewCount, 
           RP.OwnerDisplayName, COALESCE(VS.VoteCount, 0) AS VoteCount,
           COALESCE(VS.UpVotes, 0) AS Ups, COALESCE(VS.DownVotes, 0) AS Downs
    FROM RecentPosts RP
    LEFT JOIN VoteStatistics VS ON RP.Id = VS.PostId
)
SELECT P.Title, P.CreationDate, P.Score, P.ViewCount, 
       P.OwnerDisplayName, P.VoteCount, 
       P.Ups, P.Downs, 
       (CAST(P.ViewCount AS FLOAT) / NULLIF(P.Score + 1, 0)) AS ViewToScoreRatio
FROM PostWithStatistics P
ORDER BY P.Score DESC, P.ViewCount DESC
LIMIT 10;
