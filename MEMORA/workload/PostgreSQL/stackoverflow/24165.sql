
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.CreationDate, 
        p.Score, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.Score > 0 THEN 'Positive'
            WHEN rp.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS Score_Status,
        PERCENT_RANK() OVER (ORDER BY rp.Score DESC) AS Score_Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS CommentTexts
    FROM 
        Comments c
    WHERE 
        c.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        c.PostId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.UpVotes,
    pa.DownVotes,
    pa.Score_Status,
    pa.Score_Rank,
    COALESCE(rc.CommentCount, 0) AS RecentCommentCount,
    COALESCE(rc.CommentTexts, 'No comments') AS RecentComments
FROM 
    PostAnalytics pa
LEFT JOIN 
    RecentComments rc ON pa.PostId = rc.PostId
WHERE 
    pa.Score_Status = 'Positive' 
    AND (pa.CreationDate >= '2023-01-01' OR pa.Score_Rank < 0.1) 
    AND pa.UpVotes > 5
ORDER BY 
    pa.Score DESC, pa.UpVotes DESC
LIMIT 100;
