
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankWithinType
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '6 months' 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.Score, p.ViewCount, pt.Name
), 
BestPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        pt.Name AS PostType
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.RankWithinType = 1 
)

SELECT 
    bp.PostId,
    bp.Title,
    bp.PostType,
    bp.Tags,
    bp.Score,
    bp.ViewCount,
    bp.CommentCount,
    bp.UpVotes,
    bp.DownVotes,
    CASE 
        WHEN bp.UpVotes > bp.DownVotes THEN 'Positive Feedback'
        WHEN bp.UpVotes < bp.DownVotes THEN 'Negative Feedback'
        ELSE 'Neutral Feedback'
    END AS Feedback
FROM 
    BestPosts bp
ORDER BY 
    bp.Score DESC, 
    bp.ViewCount DESC;
