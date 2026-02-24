WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        array_length(string_to_array(p.Tags, '>'), 1) AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        TagCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByUser = 1 
),
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.Score,
        tp.ViewCount,
        tp.TagCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount 
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerDisplayName, tp.Score, tp.ViewCount, tp.TagCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.Score,
    ps.ViewCount,
    ps.TagCount,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    CASE 
        WHEN ps.Score > 0 THEN 'Positive'
        WHEN ps.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreCategory,
    CASE 
        WHEN ps.TagCount > 5 THEN 'Highly Tagged'
        WHEN ps.TagCount BETWEEN 3 AND 5 THEN 'Moderately Tagged'
        ELSE 'Less Tagged'
    END AS TagCategory
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC,
    ps.ViewCount DESC;