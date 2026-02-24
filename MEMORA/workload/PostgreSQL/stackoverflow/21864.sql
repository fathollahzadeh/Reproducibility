WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVoteCount
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate > (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
),
AggregatedScores AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        Author,
        Rank,
        UpVoteCount,
        DownVoteCount,
        (UpVoteCount - DownVoteCount) AS NetVote,
        CASE 
            WHEN ViewCount > 1000 THEN 'High Visibility'
            WHEN ViewCount BETWEEN 500 AND 1000 THEN 'Medium Visibility'
            ELSE 'Low Visibility' 
        END AS Visibility
    FROM RankedPosts
),
PostHistoryEvents AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        PHT.Name AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EventRank
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PHT.Id IN (10, 11, 19, 20)  
)
SELECT 
    A.Title,
    A.Score,
    A.ViewCount,
    A.Author,
    A.Rank,
    A.NetVote,
    A.Visibility,
    PH.Comment AS LastEventComment,
    PH.CreationDate AS LastEventDate,
    PH.HistoryType AS LastEventType
FROM AggregatedScores A
LEFT JOIN PostHistoryEvents PH ON A.PostId = PH.PostId AND PH.EventRank = 1
WHERE A.Rank <= 5  
ORDER BY A.Visibility DESC, A.NetVote DESC, A.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;