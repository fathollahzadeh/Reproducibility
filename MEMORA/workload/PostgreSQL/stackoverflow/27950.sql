WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY substring(Tags, 2, length(Tags)-2) ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
LatestPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
),
PostStatistics AS (
    SELECT 
        lp.PostId,
        lp.Title,
        lp.Tags,
        lp.CreationDate,
        lp.ViewCount,
        lp.Score,
        lp.AnswerCount,
        lp.CommentCount,
        lp.FavoriteCount,
        COUNT(c.Id) AS CommentCountTotal,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        LatestPosts lp
    LEFT JOIN 
        Comments c ON lp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON lp.PostId = v.PostId
    GROUP BY 
        lp.PostId, lp.Title, lp.Tags, lp.CreationDate, lp.ViewCount, lp.Score, lp.AnswerCount, lp.CommentCount, lp.FavoriteCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Tags,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.CommentCountTotal,
    ps.UpVotes,
    ps.DownVotes,
    CASE 
        WHEN ps.Score >= 10 AND ps.CommentCountTotal >= 5 THEN 'Hot'
        WHEN ps.Score >= 5 THEN 'Trending'
        ELSE 'Regular'
    END AS Popularity
FROM 
    PostStatistics ps
WHERE 
    ps.ViewCount > 100
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;