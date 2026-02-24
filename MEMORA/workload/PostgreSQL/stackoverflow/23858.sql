WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS UpVotes,
        COALESCE(NULLIF(p.Body, ''), '<No content>') AS BodyContent
    FROM 
        Posts p
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title,
        rp.BodyContent,
        rp.Score,
        rp.CreationDate,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.DownVotes > rp.UpVotes THEN 'Negative'
            WHEN rp.UpVotes > rp.DownVotes THEN 'Positive'
            ELSE 'Neutral'
        END AS FeedbackScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
        AND rp.Score IS NOT NULL
        AND (rp.Score > 100 OR rp.Title ILIKE '%SQL%')
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS AllComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.BodyContent,
    fp.Score,
    fp.CreationDate,
    fp.UpVotes,
    fp.DownVotes,
    fp.FeedbackScore,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(pc.AllComments, 'No comments yet') AS AllComments
FROM 
    FilteredPosts fp
    LEFT JOIN PostComments pc ON fp.PostId = pc.PostId
ORDER BY 
    fp.Score DESC, 
    fp.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;