WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
        AND P.Score > 0
),
TopPosts AS (
    SELECT 
        PostId,
        Title, 
        ViewCount, 
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
),
PostVotes AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    JOIN 
        TopPosts TP ON V.PostId = TP.PostId
    GROUP BY 
        V.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.ViewCount,
    TP.Score,
    PV.UpVotes,
    PV.DownVotes,
    TP.OwnerDisplayName,
    CASE 
        WHEN TP.Score >= 100 THEN 'Hot'
        WHEN TP.Score >= 50 THEN 'Trending'
        ELSE 'New'
    END AS PostStatus
FROM 
    TopPosts TP
JOIN 
    PostVotes PV ON TP.PostId = PV.PostId
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;