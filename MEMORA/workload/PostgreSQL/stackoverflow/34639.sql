WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN pt.Name = 'Question' THEN 'Q'
            WHEN pt.Name = 'Answer' THEN 'A'
            ELSE 'Other' END
            ORDER BY p.Score DESC) AS rn,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, ', ')) AS tag_name ON tag_name IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, pt.Name
),
PostWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.VoteCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.Tags,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.VoteCount, rp.UpVotes, rp.DownVotes, rp.Tags
),
FilteredPosts AS (
    SELECT 
        pwc.*,
        CASE 
            WHEN pwc.Score > 10 THEN 'High Score'
            WHEN pwc.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
            ELSE 'Low Score'
        END AS ScoreCategory, 
        RANK() OVER (ORDER BY pwc.Score DESC) AS PostRank
    FROM 
        PostWithComments pwc
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.VoteCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.CommentCount,
    fp.ScoreCategory,
    CASE 
        WHEN fp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentsStatus
FROM 
    FilteredPosts fp
WHERE 
    fp.PostRank <= 10
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;