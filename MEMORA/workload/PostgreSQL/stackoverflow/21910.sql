WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankByUser,
        rp.UpVotesCount,
        rp.DownVotesCount,
        CASE 
            WHEN rp.Score > 0 THEN 'Positive'
            WHEN rp.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByUser <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalPostData AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        pc.CommentCount,
        tp.UpVotesCount,
        tp.DownVotesCount,
        tp.ScoreCategory,
        COALESCE(pc.CommentCount, 0) AS Comments
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    fpd.PostId,
    fpd.Title,
    fpd.CreationDate,
    fpd.Score,
    fpd.ViewCount,
    fpd.CommentCount,
    fpd.UpVotesCount,
    fpd.DownVotesCount,
    fpd.ScoreCategory,
    CASE 
        WHEN fpd.Comments IS NULL THEN 'No Comments'
        WHEN fpd.Comments > 0 THEN 'Has Comments'
        ELSE 'Zero Comments'
    END AS CommentStatus
FROM 
    FinalPostData fpd
WHERE 
    fpd.ScoreCategory <> 'Neutral'
ORDER BY 
    fpd.Score DESC, 
    fpd.CreationDate DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;