WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM 
        Votes
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        pvs.UpVotesCount,
        pvs.DownVotesCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteStats pvs ON rp.Id = pvs.PostId
    LEFT JOIN 
        Comments c ON rp.Id = c.PostId
    WHERE 
        rp.RankScore <= 10
    GROUP BY 
        rp.Id, rp.Title, rp.Score, pvs.UpVotesCount, pvs.DownVotesCount
)
SELECT 
    tp.Id,
    tp.Title,
    tp.Score,
    COALESCE(tp.UpVotesCount, 0) AS UpVotes,
    COALESCE(tp.DownVotesCount, 0) AS DownVotes,
    tp.CommentCount,
    CASE 
        WHEN tp.Score > 100 THEN 'Highly Rated'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory,
    (SELECT 
        STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM 
        Tags t 
     JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%' 
     WHERE 
        p.Id = tp.Id) AS TagsList
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;