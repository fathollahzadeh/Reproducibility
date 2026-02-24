WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 YEAR' 
        AND (P.ViewCount IS NOT NULL AND P.ViewCount > 0)
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        Author
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
), 
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
PostVotes AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
), 
PostHistoryCounts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
FinalResults AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.CreationDate,
        TP.Score,
        TP.Author,
        COALESCE(PC.CommentCount, 0) AS TotalComments,
        COALESCE(PV.UpVotes, 0) AS UpVoteCount,
        COALESCE(PV.DownVotes, 0) AS DownVoteCount,
        COALESCE(PH.EditCount, 0) AS EditCount,
        PH.LastEditDate
    FROM 
        TopPosts TP
    LEFT JOIN 
        PostComments PC ON TP.PostId = PC.PostId
    LEFT JOIN 
        PostVotes PV ON TP.PostId = PV.PostId
    LEFT JOIN 
        PostHistoryCounts PH ON TP.PostId = PH.PostId
)
SELECT 
    *,
    CASE 
        WHEN Score > 100 THEN 'High Scoring'
        WHEN Score BETWEEN 50 AND 100 THEN 'Medium Scoring'
        ELSE 'Low Scoring'
    END AS ScoreCategory,
    CASE 
        WHEN LastEditDate >= cast('2024-10-01' as date) - INTERVAL '1 MONTH' THEN 'Recently Edited'
        ELSE 'Stale'
    END AS EditStatus
FROM 
    FinalResults
ORDER BY 
    Score DESC, 
    TotalComments DESC;