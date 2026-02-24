
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        TRIM(LEADING '<' FROM TRIM(TRAILING '>' FROM p.Tags)) AS CleanedTags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') 
        AND p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score, p.PostTypeId
),

FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CleanedTags, 
        rp.CommentCount, 
        rp.VoteCount, 
        rp.UpVotes, 
        rp.DownVotes, 
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)

SELECT 
    fp.PostId,
    fp.Title, 
    fp.CleanedTags,
    fp.CommentCount,
    fp.VoteCount,
    fp.UpVotes,
    fp.DownVotes,
    CASE 
        WHEN fp.UpVotes > fp.DownVotes THEN 'Positive'
        WHEN fp.UpVotes < fp.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    FilteredPosts fp
ORDER BY 
    fp.UpVotes DESC, 
    fp.CommentCount DESC;
