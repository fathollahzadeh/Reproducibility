WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.PostRank,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 AND
        rp.Score > (SELECT AVG(Score) FROM Posts) AND
        rp.CommentCount IS NOT NULL
),
FinalResults AS (
    SELECT 
        fp.Id,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.CommentCount,
        fp.UpVoteCount,
        fp.DownVoteCount,
        CASE 
            WHEN fp.Score > 100 THEN 'Hot' 
            WHEN fp.Score BETWEEN 50 AND 100 THEN 'Trending' 
            ELSE 'Normal' 
        END AS PostCategory,
        DENSE_RANK() OVER (ORDER BY fp.Score DESC) AS ScoreRank
    FROM 
        FilteredPosts fp
)
SELECT 
    fr.Id,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.CommentCount,
    fr.UpVoteCount,
    fr.DownVoteCount,
    fr.PostCategory,
    fr.ScoreRank
FROM 
    FinalResults fr
WHERE 
    fr.ScoreRank <= 10
ORDER BY 
    fr.Score DESC;
