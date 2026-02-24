WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.ViewCount,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS rn
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND P.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerReputation,
        rn
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
),
VoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Votes V
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.CreationDate,
        TP.Score,
        PS.UpVoteCount,
        PS.DownVoteCount,
        (TP.Score + COALESCE(PS.UpVoteCount, 0) - COALESCE(PS.DownVoteCount, 0)) AS AdjustedScore
    FROM 
        TopPosts TP
    LEFT JOIN 
        VoteSummary PS ON TP.PostId = PS.PostId
),
FinalResults AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.Score,
        PD.UpVoteCount,
        PD.DownVoteCount,
        PD.AdjustedScore,
        RANK() OVER (ORDER BY PD.AdjustedScore DESC) AS Rank
    FROM 
        PostDetails PD
)
SELECT 
    FR.*,
    CASE 
        WHEN FR.UpVoteCount IS NULL THEN 'No Upvotes Recorded' 
        ELSE 'Upvotes Recorded'
    END AS UpVoteStatus,
    CASE 
        WHEN FR.DownVoteCount IS NULL THEN 'No Downvotes Recorded' 
        ELSE 'Downvotes Recorded'
    END AS DownVoteStatus
FROM 
    FinalResults FR
WHERE 
    (FR.AdjustedScore > 0 AND FR.UpVoteCount IS NOT NULL)
    OR (FR.DownVoteCount IS NULL)
ORDER BY 
    FR.Rank;