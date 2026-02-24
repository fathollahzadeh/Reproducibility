WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
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
        OwnerName,
        CreationDate,
        Score,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostVotes AS (
    SELECT 
        V.PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.OwnerName,
    TP.CreationDate,
    COALESCE(PV.VoteCount, 0) AS TotalVotes,
    COALESCE(PV.UpVotes, 0) AS UpVotes,
    COALESCE(PV.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN TP.Score IS NULL THEN 'No Score'
        ELSE CASE 
            WHEN TP.Score > 50 THEN 'High Score'
            WHEN TP.Score BETWEEN 20 AND 50 THEN 'Medium Score'
            ELSE 'Low Score'
        END 
    END AS ScoreCategory
FROM 
    TopPosts TP
LEFT JOIN 
    PostVotes PV ON TP.PostId = PV.PostId
WHERE 
    TP.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
ORDER BY 
    TP.Score DESC, TP.CreationDate DESC;