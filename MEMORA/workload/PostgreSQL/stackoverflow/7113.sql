WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        OwnerReputation
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
),
VotesSummary AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
FinalResults AS (
    SELECT 
        TP.Title,
        TP.OwnerDisplayName,
        TP.OwnerReputation,
        COALESCE(VS.UpVotes, 0) AS UpVotes,
        COALESCE(VS.DownVotes, 0) AS DownVotes
    FROM 
        TopPosts TP
    LEFT JOIN 
        VotesSummary VS ON TP.PostId = VS.PostId
)
SELECT 
    Title,
    OwnerDisplayName,
    OwnerReputation,
    UpVotes,
    DownVotes
FROM 
    FinalResults
ORDER BY 
    UpVotes DESC, DownVotes ASC;