
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore,
        DENSE_RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.ViewCount DESC) AS RankViews,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COALESCE(PH.Comment, 'No comments') AS LastEditComment,
        PH.CreationDate AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.CreationDate = (
            SELECT MAX(PH2.CreationDate)
            FROM PostHistory PH2
            WHERE PH2.PostId = P.Id AND PH2.PostHistoryTypeId IN (4, 5)
        )
    WHERE 
        P.CreationDate > DATE '2024-10-01' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName, PH.Comment, PH.CreationDate
),
TopRankedPosts AS (
    SELECT 
        *,
        CASE 
            WHEN RankScore <= 3 THEN 'Top-Scorer'
            ELSE 'Regular'
        END AS RankCategory
    FROM 
        RankedPosts
    WHERE 
        RankViews <= 5
)
SELECT 
    TR.PostId,
    TR.Title,
    TR.Author,
    TR.LastEditComment,
    TR.LastEditDate,
    TR.ViewCount,
    TR.Score,
    TR.RankCategory
FROM 
    TopRankedPosts TR
WHERE 
    TR.ViewCount IS NOT NULL
    AND TR.Score > 0
    AND TR.RankCategory = 'Top-Scorer'
ORDER BY 
    TR.Score DESC, 
    TR.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
