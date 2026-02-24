WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.OwnerDisplayName
    FROM 
        RankedPosts RP
    WHERE 
        RP.RankScore <= 5
),
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        FP.PostId,
        FP.Title,
        FP.ViewCount,
        FP.OwnerDisplayName,
        PVS.UpVotes,
        PVS.DownVotes,
        (FP.ViewCount + COALESCE(PVS.UpVotes, 0) - COALESCE(PVS.DownVotes, 0)) AS AdjustedScore
    FROM 
        FilteredPosts FP
    LEFT JOIN 
        PostVoteStats PVS ON FP.PostId = PVS.PostId
)
SELECT 
    PD.Title,
    PD.ViewCount,
    PD.OwnerDisplayName,
    PD.AdjustedScore,
    COALESCE(CONCAT('This post has ', PD.UpVotes, ' upvotes and ', PD.DownVotes, ' downvotes.'), 'No votes yet!') AS VoteSummary
FROM 
    PostDetails PD
ORDER BY 
    PD.AdjustedScore DESC, 
    PD.ViewCount DESC
LIMIT 10;