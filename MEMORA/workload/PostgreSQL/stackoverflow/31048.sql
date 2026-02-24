
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopQuestions AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
EnhancedPosts AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.Score,
        pe.CommentCount,
        pe.UpVoteCount,
        pe.DownVoteCount,
        (CASE 
            WHEN pe.UpVoteCount + pe.DownVoteCount > 0 THEN 
                CAST(pe.UpVoteCount AS FLOAT) / (pe.UpVoteCount + pe.DownVoteCount)
            ELSE 0 END) AS UpvoteRatio
    FROM 
        TopQuestions tp
    JOIN 
        PostEngagement pe ON tp.PostId = pe.PostId
)
SELECT 
    ep.PostId,
    ep.Title,
    ep.ViewCount,
    ep.Score,
    ep.CommentCount,
    ep.UpVoteCount,
    ep.DownVoteCount,
    ep.UpvoteRatio
FROM 
    EnhancedPosts ep
WHERE 
    ep.UpvoteRatio > 0.5
ORDER BY 
    ep.ViewCount DESC;
