
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.AnswerCount,
        U.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        V.PostId
),
PostStatistics AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.AnswerCount,
        RP.OwnerName,
        COALESCE(RV.VoteCount, 0) AS RecentVoteCount,
        COALESCE(RV.Upvotes, 0) AS Upvotes,
        COALESCE(RV.Downvotes, 0) AS Downvotes,
        RP.PostRank
    FROM 
        RankedPosts RP
    LEFT JOIN 
        RecentVotes RV ON RP.PostId = RV.PostId
)
SELECT 
    PS.*,
    CASE 
        WHEN PS.AnswerCount > 0 THEN 'Answered'
        ELSE 'Unanswered'
    END AS PostStatus,
    (PS.Upvotes - PS.Downvotes) AS VoteBalance,
    CASE 
        WHEN PS.Score > 100 THEN 'High Score'
        WHEN PS.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    PostStatistics PS
WHERE 
    PS.PostRank <= 5
ORDER BY 
    PS.Score DESC, PS.RecentVoteCount DESC;
